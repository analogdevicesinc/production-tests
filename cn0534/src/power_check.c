/*
 * Copyright (C) 2014,2017,2018 Analog Devices, Inc.
 * Author: Paul Cercueil <paul.cercueil@analog.com>
 *         Robin Getz <robin.getz@analog.com>
 *         Travis Collins <travis.collins@analog.com>
 *
 * Licensed under the GPL-2.
 *
 * */

#include <errno.h>
#include <getopt.h>
#include <iio.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <math.h>
#include <unistd.h>
#include <complex.h>
#include <fftw3.h>
#include <fcntl.h>
#ifdef _WIN32
    #include <float.h>
    #include "util.h"
#else
    #include <values.h>
#endif

#define SAMPLES_PER_READ 1048576

#define TONE_FREQUENCY 3000000 // must be positive

#define TOLERANCE_HZ 1000

#define SCALE 0.4

#define MAX_SCALE 0.45

#define SFDR_REQUIREMENT 25

#define RSSI_REQUIREMENT 50

#define PEAK_REQUIREMENT 10

#define IIO_IN false
#define IIO_OUT true

uint32_t i, rssi, nb_channels, sample_rate = 30720000;
uint64_t rx_lo = 0, tx_lo = 0, external_tone = 0, serial;
unsigned int buffer_size = SAMPLES_PER_READ;
long long xo = 0, true_tx_lo=0, true_rx_lo=0;
int c, c1, c2, c3, c4, c5, true_tone_freq, option_index = 0, arg_index = 0,
        uri_index = 0, fline, log_mode = 0, param_line=0;
float tx_scale, freq_tol, scale_req, sfdr_req, rssi_req ;
//uint32_t test_num=0;

size_t sample_size, len=0;
int timeout = -1;
bool scan_for_context = false, save_data = false, 
    conf_file_given = false, log_enabled = false;
char buf[256], hashtag[5]= "#";
char *line = NULL;
fftw_complex *in_c, *out;
fftw_plan plan_forward;
double *win;
double error = 0;
struct iio_channel *rx_i;
FILE *fd = NULL;
FILE *conf_fptr = NULL; //file pointer to the configuration/limit file
FILE *log_fptr = NULL;  //file pointer to the test fail logs.


static const struct option options[] = {
    {"help", no_argument, 0, 'h'},
    {"uri", required_argument, 0, 'u'},
    {"buffer-size", required_argument, 0, 'b'},
    {"samples", required_argument, 0, 's'},
    {"rxlo-freq", required_argument, 0, 'r'},
    {"txlo-freq", required_argument, 0, 't'},
    {"external-tone", required_argument, 0, 'e'},
    {"timeout", required_argument, 0, 'T'},
    {"auto", no_argument, 0, 'a'},
    {"data-file", no_argument, 0, 'f'},
    {"config", required_argument, 0, 'c'},
    {"log", required_argument, 0, 'l'},
    {"repeat", no_argument, 0, 'R'},
    {"ignore", no_argument, 0, 'i'},
    { NULL, no_argument, NULL, 0 }
};

static const char *options_descriptions[] = {
    "Show this help and quit.",
    "Use the context with the provided URI.",
    "Size of capture buffers. Default is 1048576.",
    "Number of buffers to capture, 0 = infinite. Default is 1",
    "Rx LO frequency in Hz. Default is 0. 0 is off",
    "Tx LO frequency in Hz. Default is 0. 0 is off",
    "External Tone in Hz. Default is 0. 0 is off",
    "Buffer timeout in milliseconds. 0 = no timeout",
    "Scan for available contexts and if only one is available use it.",
    "Save captured data to a file.",
    "Path of configuration/limit file.",
    "Enable logging. \
            \n0 -> Only failed tests are logged.\
            \n1 -> Both passed and failed tests are logged\
            \n2 -> Only failed tests are logged and deletes previous logs.\
            \n3 -> Both passed and failed tests are logged and deletes previous logs.",
    "Run test repeatedly.",
    "Ignore Failed tests. Continue running tests."

};

struct test_params {
    float peak; //highest peak in dBFS
    float freq_tol; // frequency tolerance of expected RX peak in hz
    float sfdr; // sfdr in dBFS
    float rssi; // rssi value
    float peak_tx_lo_disabled;
};

static void usage(const char *name)
{
    unsigned int i;

    printf("Usage:\n\t %s [-T <timeout-ms>] [-b <buffer-size>] [-s <samples>] "
           "<iio_device> [<channel> ...]\n\nOptions:\n",
           name);
    for (i = 0; options[i].name; i++)
        printf("\t-%c, --%s\n\t\t\t%s\n",
               options[i].val, options[i].name,
               options_descriptions[i]);
}

static struct iio_context *ctx;
static struct iio_buffer *buffer;
static size_t num_samples = 1;
bool stop = false;

static volatile sig_atomic_t app_running = true;
static int exit_code = EXIT_SUCCESS;

static void handle_sig(int sig)
{
    printf("Waiting for process to finish...%d\n", sig);
    stop = true;
}

static void quit_all(int sig)
{
    exit_code = sig;
    app_running = false;
    if (buffer)
        iio_buffer_cancel(buffer);
    if (log_fptr!=NULL)
    {
        fclose(log_fptr);
        log_fptr=NULL;
    }
        
    if (conf_fptr!=NULL)  
    {
        fclose(conf_fptr);
        conf_fptr=NULL;
    }
        
}

#ifdef _WIN32

#include <windows.h>

BOOL WINAPI sig_handler_fn(DWORD dwCtrlType)
{
    /* Runs in its own thread */

    switch (dwCtrlType)
    {
    case CTRL_C_EVENT:
    case CTRL_CLOSE_EVENT:
        quit_all(SIGTERM);
        return TRUE;
    default:
        return FALSE;
    }
}

static void setup_sig_handler(void)
{
    SetConsoleCtrlHandler(sig_handler_fn, TRUE);
}

#elif NO_THREADS

static void sig_handler(int sig)
{
    /*
     * If the main function is stuck waiting for data it will not abort. If the
     * user presses Ctrl+C a second time we abort without cleaning up.
     */
    if (!app_running)
        exit(sig);
    app_running = false;
}

static void set_handler(int sig)
{
    struct sigaction action;

    sigaction(sig, NULL, &action);
    action.sa_handler = sig_handler;
    sigaction(sig, &action, NULL);
}

static void setup_sig_handler(void)
{
    set_handler(SIGHUP);
    set_handler(SIGPIPE);
    set_handler(SIGINT);
    set_handler(SIGSEGV);
    set_handler(SIGTERM);
}

#else

#include <pthread.h>

static void *sig_handler_thd(void *data)
{
    sigset_t *mask = data;
    int ret, sig;

    /* Blocks until one of the termination signals is received */
    do
    {
        ret = sigwait(mask, &sig);
    } while (ret == EINTR);

    quit_all(ret);

    return NULL;
}

static void setup_sig_handler(void)
{
    sigset_t mask, oldmask;
    pthread_t thd;
    int ret;

    /*
     * Async signals are difficult to handle and the IIO API is not signal
     * safe. Use a seperate thread and handle the signals synchronous so we
     * can call iio_buffer_cancel().
     */

    sigemptyset(&mask);
    sigaddset(&mask, SIGHUP);
    sigaddset(&mask, SIGPIPE);
    sigaddset(&mask, SIGINT);
    sigaddset(&mask, SIGSEGV);
    sigaddset(&mask, SIGTERM);

    pthread_sigmask(SIG_BLOCK, &mask, &oldmask);

    ret = pthread_create(&thd, NULL, sig_handler_thd, &mask);
    if (ret)
    {
        fprintf(stderr, "Failed to create signal handler thread: %d\n", ret);
        pthread_sigmask(SIG_SETMASK, &oldmask, NULL);
    }
}

#endif

void set_led_state(uint8_t state)
{
    FILE *fd;
    char *buff;
    switch (state)
    {
        case 1: //fail
            buff="none";
            break;
        case 2: //pass
            buff="default-on";
            break;
        case 0: //running
            buff="timer";
            break;
    }

#ifdef REMOTE
    printf("LED: %s\n", buff);
#else
    fd = fopen("/sys/class/leds/led0:green/trigger", "w");
    fprintf(fd, buff);
    fclose(fd);
    if (state==0)
    {
        fd = fopen("/sys/class/leds/led0:green/delay_on", "w");
        fprintf(fd, "50");
        fclose(fd);
        fd = fopen("/sys/class/leds/led0:green/delay_off", "w");
        fprintf(fd, "50");
        fclose(fd);
    }
#endif
}

static struct iio_context *scan(void)
{
    struct iio_scan_context *scan_ctx;
    struct iio_context_info **info;
    struct iio_context *ctx = NULL;
    unsigned int i;
    ssize_t ret;

    scan_ctx = iio_create_scan_context(NULL, 0);
    if (!scan_ctx)
    {
        fprintf(stderr, "Unable to create scan context\n");
        return NULL;
    }

    ret = iio_scan_context_get_info_list(scan_ctx, &info);
    if (ret < 0)
    {
        char err_str[1024];
        iio_strerror(-ret, err_str, sizeof(err_str));
        fprintf(stderr, "Scanning for IIO contexts failed: %s\n", err_str);
        goto err_free_ctx;
    }

    if (ret == 0)
    {
        printf("No IIO context found.\n");
        goto err_free_info_list;
    }

    if (ret == 1)
    {
        ctx = iio_create_context_from_uri(iio_context_info_get_uri(info[0]));
    }
    else
    {
        fprintf(stderr, "Multiple contexts found. Please select one using --uri:\n");

        for (i = 0; i < (size_t)ret; i++)
        {
            fprintf(stderr, "\t%d: %s [%s]\n", i,
                    iio_context_info_get_description(info[i]),
                    iio_context_info_get_uri(info[i]));
        }
    }

err_free_info_list:
    iio_context_info_list_free(info);
err_free_ctx:
    iio_scan_context_destroy(scan_ctx);

    return ctx;
}

struct write_l
{
    char *device;
    char *channel;
    bool in_out;
    char *attribute;
    char *value;
};

struct write_l write_log[128];
static int wl_index = 0;

static int32_t iio_set_attribute(char *device, char *channel, bool in_out,
                              char *attribute, char *buffer, bool log)
{
    struct iio_device *dev;
    struct iio_channel *chan;
    const char *attr;
    ssize_t ret;
    char buf[1024];

    dev = iio_context_find_device(ctx, device);
    if (!dev)
    {
        fprintf(stderr, "Device %s not found\n", device);
        iio_context_destroy(ctx);
        return EXIT_FAILURE;
    }

    chan = iio_device_find_channel(dev, channel, in_out);
    if (!chan)
    {
        fprintf(stderr, "%s channel not found in %s\n", channel, device);
        iio_context_destroy(ctx);
        return EXIT_FAILURE;
    }

    attr = iio_channel_find_attr(chan, attribute);
    if (!attr)
    {
        fprintf(stderr, "%s attribute not found in %s:%s\n", attribute, device,
                channel);
        iio_context_destroy(ctx);
        return EXIT_FAILURE;
    }

    ret = iio_channel_attr_read(chan, attribute, buf, sizeof(buf));
    if (ret > 0)
    {
        /*if (log)
        {
            write_log[wl_index].device = strdup(device);
            write_log[wl_index].channel = strdup(channel);
            write_log[wl_index].in_out = in_out;
            write_log[wl_index].attribute = strdup(attribute);
            write_log[wl_index].value = strdup(buf);
            wl_index++;
        }*/
    }

    if (buffer)
    {
        ret = iio_channel_attr_write(chan, attribute, buffer);
        if (ret < 0)
        {
            printf("write '%s' failed to %s:%s:%s\n", buffer, device, channel, attribute);
            iio_context_destroy(ctx);
            return EXIT_FAILURE;
        }
    }
    return EXIT_SUCCESS;
}

int32_t setup_tx(uint64_t tx_lo_freq, float tx_scale)
{
    printf("**** Setup TX\n");
    sprintf(buf, "%llu", tx_lo_freq);
    printf("TX frequency in:\n %s", buf);
    if (iio_set_attribute("ad9361-phy", "TX_LO", IIO_OUT, "powerdown", "0", true) ||
        iio_set_attribute("ad9361-phy", "TX_LO", IIO_OUT, "frequency", buf, true))
        return EXIT_FAILURE;
    // sprintf(buf, "%u", sample_rate / 3);
    sprintf(buf, "%d", TONE_FREQUENCY);
    if (iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F1", IIO_OUT, "frequency",
                           buf, true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F2", IIO_OUT, "frequency", buf,
                           true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F1", IIO_OUT, "frequency", buf,
                           true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F2", IIO_OUT, "frequency", buf,
                           true))
        return EXIT_FAILURE;
    else
    {
        iio_channel_attr_read(
            iio_device_find_channel(
                iio_context_find_device(ctx, "cf-ad9361-dds-core-lpc"),
                "TX1_I_F1", IIO_OUT),
            "frequency", buf, sizeof(buf));
        true_tone_freq = atoi(buf);
    }
    
    sprintf(buf, "%f", tx_scale);
    if (iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F1", IIO_OUT, "scale",
                           buf, true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F2", IIO_OUT, "scale",
                           buf, //0.4
                           true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F1", IIO_OUT, "scale", buf,
                           true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F2", IIO_OUT, "scale",
                           buf, //0.4
                           true))
        return EXIT_FAILURE;

    if (iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F1", IIO_OUT, "phase",
                           "90000", true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F2", IIO_OUT, "phase", "90000",
                           true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F1", IIO_OUT, "phase",
                           "0", // Set to 0 to make tone positive, 180000 for negative
                           true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F2", IIO_OUT, "phase", "0",
                           true))
        return EXIT_FAILURE;

    if (iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F1", IIO_OUT, "raw", "1",
                           true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_I_F2", IIO_OUT, "raw", "1", true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F1", IIO_OUT, "raw", "1", true) ||
        iio_set_attribute("cf-ad9361-dds-core-lpc", "TX1_Q_F2", IIO_OUT, "raw", "1", true))
        return EXIT_FAILURE;

    if (iio_set_attribute("ad9361-phy", "voltage0", IIO_OUT, "hardwaregain",
                           "-10", false))
        return EXIT_FAILURE;
    
    return EXIT_SUCCESS;
}

int32_t setup_rx(uint64_t rx_lo_freq)
{
    printf("**** Setup RX\n");
    if (rx_lo_freq >= 6000000000)
    {
        printf("rx_out of range\n");
        fprintf(stderr, "rx_out of range\n");
        return EXIT_FAILURE;
    }
    sprintf(buf, "%llu", (unsigned long long) rx_lo_freq);
    printf("RX frequency in buf:\n %s", buf);
    if (iio_set_attribute("ad9361-phy", "RX_LO", IIO_OUT, "frequency", buf, true))
        return EXIT_FAILURE;
    iio_channel_attr_read(
        iio_device_find_channel(
            iio_context_find_device(ctx, "ad9361-phy"),
            "RX_LO", IIO_OUT),
        "frequency", buf, sizeof(buf));

    iio_device_attr_read_longlong(iio_context_find_device(ctx, "ad9361-phy"),
                                  "xo_correction", &xo);


    if (iio_set_attribute("ad9361-phy", "voltage0", IIO_IN, "gain_control_mode",
                           "manual", true))
        return EXIT_FAILURE;
    if (iio_set_attribute("ad9361-phy", "voltage0", IIO_IN, "hardwaregain",
                           "0", false))
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}

int32_t tx_lo_disable()
{
    printf("**** Disabling TX\n");
    if (iio_set_attribute("ad9361-phy", "TX_LO", IIO_OUT, "powerdown", "1", true))
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}

int32_t run_test(struct test_params limits, struct test_params * actual, struct  test_params * actual_lo_disabled, bool * result, bool tx_lo_stat)
{
    //Read RX
    // while (app_running) {

    //printf("########## Loop %d ###########\n", jj);
    int ret;
    uint8_t retries=0, retry_limit=3;
    unsigned int j, k, cnt, bin[5];
    double mag[5], peak[5], side[2];
    while(true)
    {
        // Grab some data
        ret = iio_buffer_refill(buffer);
        printf("here %d\n",ret);
        if (ret < 0)
        {
            if (app_running)
            {
                char buf[256];
                iio_strerror(-ret, buf, sizeof(buf));
                fprintf(stderr, "Unable to refill buffer: %s\n", buf);
            }
            return EXIT_FAILURE;
        }

        /* If there are only the samples we requested, we don't need to
            * demux */
        if (iio_buffer_step(buffer) == (ptrdiff_t)sample_size)
        {
            void *data, *end;
            ptrdiff_t inc;
            double actual_bin;
            printf("buffer match\n");
            end = iio_buffer_end(buffer);
            inc = iio_buffer_step(buffer);

            for (cnt = 0, data = iio_buffer_first(buffer, rx_i); data < end;
                    data += inc, cnt++)
            {
                const int16_t real = ((int16_t *)data)[0]; // Real (I)
                const int16_t imag = ((int16_t *)data)[1]; // Imag (Q)

                in_c[cnt] = (real * win[cnt] + I * imag * win[cnt]) / 2048;
            }

            fftw_execute(plan_forward);

            for (j = 0; j <= 2; j++)
            {
                peak[j] = -FLT_MAX;
                bin[j] = 0;
            }

            if (save_data)
                fd = fopen("./dat.bin", "w");

            // Find Peaks of FFT
            unsigned long long buffer_size_squared = (unsigned long long)buffer_size *
                                                        (unsigned long long)buffer_size;

            for (i = 1; i < buffer_size; ++i)
            {
                mag[2] = mag[1];
                mag[1] = mag[0];
                mag[0] = 10 * log10((creal(out[i]) * creal(out[i]) + cimag(out[i]) * cimag(out[i]))/
                                    buffer_size_squared);
                if (fd)
                    fprintf(fd, "%f\n", mag[0]);
                if (i < 2)
                    continue;
                for (j = 0; j <= 2; j++)
                {
                    if ((mag[1] > peak[j]) &&
                        ((!((mag[2] > mag[1]) && (mag[1] > mag[0]))) &&
                            (!((mag[2] < mag[1]) && (mag[1] < mag[0])))))
                    {
                        for (k = 2; k > j; k--)
                        {
                            peak[k] = peak[k - 1];
                            bin[k] = bin[k - 1];
                        }
                        peak[j] = mag[1];
                        bin[j] = i - 1;
                        if (j == 0)
                        {
                            side[0] = mag[0];
                            side[1] = mag[2];
                        }
                        break;
                    }
                }
            }
            if (fd)
                fclose(fd);
            fd = NULL;

            printf("peaks at ");
            for (j = 0; j <= 2; j++)
                printf("%f (%i); ", peak[j], bin[j]);
            printf("\nSFDR = %f dBFS\n", peak[0] - peak[1]);

            if (peak[0] < (peak[1] + 20))
            {
                printf("can't find strong signal, fix signal source\n");
                // quit_all(EXIT_FAILURE);
            }
            /* based on
                * https://ccrma.stanford.edu/~jos/sasp/Quadratic_Interpolation_Spectral_Peaks.html
                */
            actual_bin = bin[0] + (side[0] - side[1]) / (2.0 * (side[0] - 2 * peak[0] +
                                                                side[1]));

            // FFT shift
            if (actual_bin > (buffer_size / 2 + 1))
                actual_bin = actual_bin - buffer_size;

            error = fabs((actual_bin * sample_rate / buffer_size) - (double)true_tone_freq);
            printf("Peak Frequency : %lf Hz (Error %f Hz)\n",
                    actual_bin * sample_rate / buffer_size, error);

            // Read RSSI
            iio_channel_attr_read(
                iio_device_find_channel(
                    iio_context_find_device(ctx, "ad9361-phy"),
                    "voltage0", false),
                "rssi", buf, sizeof(buf));
            rssi = atoi(buf);
            printf("RSSI: %u dB\n", rssi);

            if (tx_lo_stat)
            {
                // Checks
                c1 = peak[0] > limits.peak; //peak power - tx lo enabled
                c2 =  error < limits.freq_tol;  // Frequency Accuracy (Hz)
                c3 = peak[0] > (peak[1] + limits.sfdr); // SFDR (dBFS)
                c4 = (rssi < limits.rssi);
                actual->peak = peak[0];
                actual->freq_tol = error;
                actual->sfdr = peak[0] - peak[1]; 
                actual->rssi = rssi;  

                if (c1 && c2 && c3 && c4) 
                {
                    printf("Passed\n");
                    *result = true;
                    return EXIT_SUCCESS;
                }
                else
                {
                    if (retries >= retry_limit)
                    {
                        printf("Failed\n");
                        retries=0;
                        *result = false;
                        return EXIT_SUCCESS;
                    }
                    else
                    {
                        retries++;
                    }
                }    
            }
            else
            {
                c5 = peak[0] < limits.peak_tx_lo_disabled;
                actual_lo_disabled->peak = peak[0];

                if (c5) 
                {
                    printf("Passed\n");
                    *result = true;
                    return EXIT_SUCCESS;
                }
                else
                {
                    if (retries >= retry_limit)
                    {
                        printf("Failed\n");
                        retries=0;
                        *result = false;
                        return EXIT_SUCCESS;
                    }
                    else
                    {
                        retries++;
                    } 
                }    
            }       
        }
    }   
}

static double win_hanning(int j, int n)
{
    double a = 2.0 * M_PI / (n - 1), w;
    w = 0.5 * (1.0 - cos(a * j));
    return (w);
}

int main(int argc, char **argv)
{
    struct iio_device *dev;
    struct test_params limits, measured, measured_lo_disabled;
    bool result, result_lo_disabled = true, oneshot = true, ignore=false;
    uint16_t err_cnt=0;
    tx_scale = SCALE;
    // default limits
    limits.freq_tol = TOLERANCE_HZ;
    limits.sfdr = SFDR_REQUIREMENT;
    limits.rssi = RSSI_REQUIREMENT;
    while ((c = getopt_long(argc, argv, "+hfu:b:s:T:ar:t:e:g:c:l:Ri",
                            options, &option_index)) != -1)
    {
        switch (c)
        {
        case 'h':
            usage(argv[0]);
            return EXIT_SUCCESS;
        case 'f':
            arg_index += 1;
            save_data = true;
            break;
        case 'u':
            arg_index += 2;
            uri_index = arg_index;
            break;
        case 'a':
            arg_index += 1;
            scan_for_context = true;
            break;
        case 'b':
            arg_index += 2;
            buffer_size = atoi(argv[arg_index]);
            break;
        case 's':
            arg_index += 2;
            num_samples = atoi(argv[arg_index]);
            break;
        case 'T':
            arg_index += 2;
            timeout = atoi(argv[arg_index]);
            break;
        case 'r':
            arg_index += 2;
            rx_lo = strtoll(argv[arg_index], NULL, 10);
            if (tx_lo || external_tone)
            {
                fprintf(stderr, "-e -r -t are not compatible\n");
                return EXIT_FAILURE;
            }
            break;
        case 't':
            arg_index += 2;
            tx_lo = strtoll(argv[arg_index], NULL, 10);
            if (rx_lo || external_tone)
            {
                fprintf(stderr, "-e -r -t are not compatible\n");
                return EXIT_FAILURE;
            }
            break;
        case 'e':
            arg_index += 2;
            external_tone = strtoll(argv[arg_index], NULL, 10);
            if (rx_lo || tx_lo)
            {
                fprintf(stderr, "-e -r -t are not compatible\n");
                return EXIT_FAILURE;
            }
            break;
        case 'c':
            arg_index += 2;
            rx_lo=0;
            tx_lo=0;
            conf_fptr=fopen(argv[arg_index],"r+");
            if (conf_fptr==NULL)
            {
                fprintf(stderr, "Unable to open configuration and limit file.\n");
                return EXIT_FAILURE;
            }
            conf_file_given = true;
            break;
        case 'l':
            arg_index += 2; 
            log_mode=strtoll(argv[arg_index], NULL, 10);
            log_enabled = true;

            break;
        case 'R':
            arg_index += 1;
            oneshot = false;
            break;
        case 'i':
            arg_index += 1;
            ignore = true;
            break;
        case '?':
            return EXIT_FAILURE;
        }
    }

    num_samples = num_samples * buffer_size;

    if (arg_index >= argc)
    {
        fprintf(stderr, "Incorrect number of arguments.\n\n");
        usage(argv[0]);
        return EXIT_FAILURE;
    }

    if (!rx_lo && tx_lo)
    {
        rx_lo = tx_lo;
    }

    if (!rx_lo && external_tone)
    {
        rx_lo = external_tone - sample_rate / 3;
    }

    setup_sig_handler();

    if (scan_for_context)
        ctx = scan();
    else if (uri_index)
        ctx = iio_create_context_from_uri(argv[uri_index]);
    else
        ctx = iio_create_default_context();

    if (!ctx)
    {
        fprintf(stderr, "Unable to create IIO context\n");
        return EXIT_FAILURE;
    }

    if (timeout >= 0)
        iio_context_set_timeout(ctx, timeout);
    
    // Listen to ctrl+c and ASSERT
    signal(SIGINT, handle_sig);

    // Setting up FFTW.
    win = fftw_malloc(sizeof(double) * buffer_size);
    in_c = fftw_malloc(sizeof(fftw_complex) * buffer_size);
    out = fftw_malloc(sizeof(fftw_complex) * (buffer_size + 1));
    plan_forward = fftw_plan_dft_1d(buffer_size, in_c, out, FFTW_FORWARD,
                                    FFTW_ESTIMATE);
    for (i = 0; i < buffer_size; i++)
        win[i] = win_hanning(i, buffer_size);

    //setup sampling rate
    sprintf(buf, "%u", sample_rate);
    if (iio_set_attribute("ad9361-phy", "voltage0", IIO_OUT, "sampling_frequency", buf,
                           true))
        return EXIT_FAILURE;

    dev = iio_context_find_device(ctx, "cf-ad9361-lpc");
    
    if (!dev)
    {
        fprintf(stderr, "Device %s not found\n", "cf-ad9361-lpc");
        iio_context_destroy(ctx);
        return EXIT_FAILURE;
    }
        
    rx_i = iio_device_find_channel(dev,"voltage0", 0);
    // Setup buffers so we always get fresh data
    iio_device_set_kernel_buffers_count(dev, 1);

    nb_channels = iio_device_get_channels_count(dev);

    /* Enable all channels */
    for (i = 0; i < nb_channels; i++)
        iio_channel_enable(iio_device_get_channel(dev, i));

    sample_size = iio_device_get_sample_size(dev);
    printf("enabled %i channels\n", nb_channels);
    buffer = iio_device_create_buffer(dev, buffer_size, false);
    if (!buffer)
    {
        char buf[256];
        iio_strerror(errno, buf, sizeof(buf));
        fprintf(stderr, "Unable to allocate buffer: %s\n", buf);
        iio_context_destroy(ctx);
        return EXIT_FAILURE;
    }
    
        //if conf_file_given, rx_lo, tx_lo, and the tx scale will be based on the parsed parameters.
                        
    if (conf_file_given)
    {
        set_led_state(0);
        while(true)
        {
            param_line=0;
            if(log_enabled)
            {
                if (log_mode & 0x02)
                {
                    log_fptr=fopen("test.csv", "w+");
                    fprintf(log_fptr, "Activity, param line, Test Result, TX_LO, tx scale(0.0-1.0), RX_LO, freq tol(hz), peak scale (dBFS), min SFDR (dBFS), min RSSI, min peak\n");
                    if (log_fptr)    
                        fclose(log_fptr);
                    log_fptr=NULL;

                }

            }
            err_cnt = 0;
            while ((fline = getline(&line, &len, conf_fptr)) != -1)
            {
                if (!strstr(line, hashtag) && strstr(line, ",")){
                    
                    param_line++;
                    log_fptr=fopen("test.csv", "a+");
                    tx_lo = atoll(strtok (line, ","));
                    tx_scale = atof(strtok (NULL, ","));
                    rx_lo = atoll(strtok (NULL, ","));
                    limits.peak = atof(strtok (NULL, ","));
                    limits.freq_tol = atof(strtok (NULL, ","));
                    limits.sfdr = atof(strtok (NULL, ","));
                    limits.rssi = atof(strtok (NULL, ","));
                    limits.peak_tx_lo_disabled = atof(strtok (NULL, ",\n"));

                    //print tx and rx lo 

                    setup_rx(rx_lo);

                    setup_tx(tx_lo,tx_scale);

                    /* pause for RSSI to stablize */
                    usleep(100000); 

                    // test
                    #ifdef REMOTE
                        printf("Param #%d\n",param_line);
                    #endif
                    run_test(limits, &measured, &measured_lo_disabled, &result, true);
                    usleep(100000);

                    if (tx_scale < MAX_SCALE) 
                    {
                        tx_lo_disable();
                    
                        usleep(100000);

                        run_test(limits, &measured, &measured_lo_disabled, &result_lo_disabled, false);
                    }
                    
                    if (result && result_lo_disabled)
                    {
                        if (oneshot && log_enabled && (log_mode & 0x01))
                        {
                            fprintf(log_fptr, "TEST, %d, PASSED, %llu, %f, %llu, %f, %f, %f, %f, %f\n", 
                                            param_line,
                                            tx_lo, tx_scale, rx_lo, 
                                            measured.peak,
                                            measured.freq_tol,
                                            measured.sfdr,
                                            measured.rssi,
                                            measured_lo_disabled.peak);
                        }
                    }
                    else
                    {
                        err_cnt++;
                        if (oneshot && log_enabled)
                        {
                            fprintf(log_fptr, "TEST, %d, FAILED, %llu, %f, %llu, %f, %f, %f, %f, %f\n", 
                                            param_line,
                                            tx_lo, tx_scale, rx_lo, 
                                            measured.peak,
                                            measured.freq_tol,
                                            measured.sfdr,
                                            measured.rssi,
                                            measured_lo_disabled.peak);
                        }
                    }
                    if (log_fptr)    
                        fclose(log_fptr);
                    log_fptr=NULL;
                    if (!(result && result_lo_disabled) && !ignore)
                    {
                        break; //Stop test if encountered failed test.
                    }
                }
            }
            if (err_cnt)
            {
                #ifdef REMOTE
                    printf("%d test(s) failed!\n", err_cnt);
                #endif
                set_led_state(1);
            }
            else
            {
                #ifdef REMOTE
                    printf("All tests Passed.\n");
                #endif
                set_led_state(2); //led status if passed    
            }

            if(oneshot)
            {
                #ifdef REMOTE
                    printf("Oneshot only.....\n");
                #endif
                break;
            }

            rewind(conf_fptr);
        }
    }
    else 
    {
        // Use cli-provided rx_lo and  tx_lo. Use default scale
        limits.freq_tol = TOLERANCE_HZ;
        limits.sfdr = SFDR_REQUIREMENT;
        limits.rssi = RSSI_REQUIREMENT;
        limits.peak = PEAK_REQUIREMENT;

        setup_rx(rx_lo);

        setup_tx(tx_lo,tx_scale);

        /* pause for RSSI to stablize */
        usleep(100000);

        // first turn off led
        set_led_state(0);
        // test
        while (true)
        {
            if(log_enabled)
            {
                if (log_mode & 0x02)
                {
                    log_fptr=fopen("test.csv", "w+");
                }
                else
                {
                    log_fptr=fopen("test.csv", "a+");
                }
            }
            run_test(limits, &measured, &measured_lo_disabled, &result, true);

            tx_lo_disable();

            usleep(100000);

            run_test(limits, &measured, &measured_lo_disabled, &result_lo_disabled, false);

            if (result && result_lo_disabled)
            {
                set_led_state(2); //led status if passed
                if (oneshot && log_enabled && (log_mode & 0x01))
                {
                    fprintf(log_fptr, "TEST, %d, PASSED, %llu, %f, %llu, %f, %f, %f, %f\n", 
                                    param_line,
                                    tx_lo, tx_scale, rx_lo, 
                                    measured.freq_tol,
                                    measured.sfdr,
                                    measured.rssi,
                                    measured_lo_disabled.peak);
                }
            }
            else 
            {
                set_led_state(1); //led status if failed
                if (oneshot && log_enabled)
                {
                    fprintf(log_fptr, "TEST, %d, FAILED, %llu, %f, %llu, %f, %f, %f, %f\n", 
                                    param_line,
                                    tx_lo, tx_scale, rx_lo, 
                                    measured.freq_tol,
                                    measured.sfdr,
                                    measured.rssi,
                                    measured_lo_disabled.peak);
                }
            }
            if (log_fptr!=NULL)    
                fclose(log_fptr);
            if (oneshot)
                break;
        }                             
                    
    }
    #ifdef REMOTE
        printf("Exiting.....\n");
    #endif
    if (conf_fptr!=NULL)  
        fclose(conf_fptr);
    iio_buffer_destroy(buffer);
    iio_context_destroy(ctx);
    return exit_code;
}