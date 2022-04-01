#ifndef _UTIL_H_
#define _UTIL_H_
extern ssize_t getdelim(char **linep, size_t *n, int delim, FILE *fp);

extern ssize_t getline(char **linep, size_t *n, FILE *fp);
#endif