/*
# Name: btogorea
# Date: 2/14/2024
# Version: 6.6.0
#
# I2C Address(0x), Register Address(0x), Register Value(0x), Read Modify Write(0x)
#
# THIS DATA FILE, AND ALL INFORMATION CONTAINED THEREIN,
# IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL ANALOG DEVICES, INC. BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE DATA FILE,
# THE INFORMATION CONTAINED THEREIN, OR ITS USE FOR ANY PURPOSE.
# BEFORE USING THIS DATA FILE IN ANY APPLICATION FOR PRODUCTION OR DEPLOYMENT,
# THE CUSTOMER IS SOLELY RESPONSIBLE FOR TESTING AND VERIFYING
# THE CONTENT OF THIS DATA FILE IN CONNECTION WITH THEIR PRODUCTS AND SYSTEM(S).
# ---------------------------------------------------------------------------------
#
#            _____ _____
#      /\   |  __ \_   _|
#     /  \  | |  | || |
#    / /\ \ | |  | || |
#   / ____ \| |__| || |_
#  /_/    \_\_____/_____|
#
# ---------------------------------------------------------------------------------
*/
/*
# This script is validated on:
# MAX96717
# MAX96724
# Please refer to the Errata sheet for each device.
# ---------------------------------------------------------------------------------
*/
//
// CSIConfigurationTool
// Deserializer: MAX96724 / Mode: 2 (1x4) / Device Address: 0x4E
// Pipe0:
// GMSL-A Input Stream: VC0 RGB888 PortB - Output Stream: VC0 RGB888 PortA (D-PHY)

0x04,0x4E,0x04,0x0B,0x00, // BACKTOP : BACKTOP12 | CSI_OUT_EN (CSI_OUT_EN): CSI output disabled
// Link Initialization for Deserializer
0x04,0x4E,0x00,0x06,0xFF, // DEV : REG6 | (Default) LINK_EN_A (LINK_EN_A): Enabled | (Default) LINK_EN_B (LINK_EN_B): Enabled | (Default) LINK_EN_C (LINK_EN_C): Enabled | (Default) LINK_EN_D (LINK_EN_D): Enabled
0x04,0x4E,0x00,0x03,0xAA, // DEV : REG3 | (Default) DIS_REM_CC_A (GMSL Link A I2C Port 0): Enabled | (Default) DIS_REM_CC_B (GMSL Link B I2C Port 0): Enabled | (Default) DIS_REM_CC_C (GMSL Link C I2C Port 0): Enabled | (Default) DIS_REM_CC_D (GMSL Link D I2C Port 0): Enabled
0x00,0x01, // Warning: The actual recommended delay is 5 usec.
//
// INSTRUCTIONS FOR DESERIALIZER MAX96724
//
// Video Pipes And Routing Configuration
0x04,0x4E,0x00,0xF0,0x62, // VIDEO_PIPE_SEL : VIDEO_PIPE_SEL_0 | (Default) VIDEO_PIPE_SEL_0 (Pipe 0 GMSL2 PHY): A | VIDEO_PIPE_SEL_0 (Pipe 0 Input Pipe): X
0x04,0x4E,0x00,0xF4,0x1F, // VIDEO_PIPE_SEL : VIDEO_PIPE_EN | (Default) VIDEO_PIPE_EN (Video Pipe 0): Enabled | VIDEO_PIPE_EN (Video Pipe 1): Enabled | VIDEO_PIPE_EN (Video Pipe 2): Disabled | VIDEO_PIPE_EN (Video Pipe 3): Disabled | STREAM_SEL_ALL (Stream Select All): Disabled
// Pipe to Controller Mapping Configuration
0x04,0x4E,0x09,0x0B,0x00, // MIPI_TX__0 : MIPI_TX11 | (Default) MAP_EN_L (MAP_EN_L Pipe 0): 0x0
0x04,0x4E,0x09,0x0C,0x00, // MIPI_TX__0 : MIPI_TX12 | (Default) MAP_EN_H (MAP_EN_H Pipe 0): 0x0
0x04,0x4E,0x09,0x0D,0x00, // MIPI_TX__0 : MIPI_TX13 | (Default) MAP_SRC_0 (MAP_SRC_0 Pipe 0 DT): 0x0 | (Default) MAP_SRC_0 (MAP_SRC_0 Pipe 0 VC): 0x0
0x04,0x4E,0x09,0x0E,0x00, // MIPI_TX__0 : MIPI_TX14 | (Default) MAP_DST_0 (MAP_DST_0 Pipe 0 DT): 0x0 | (Default) MAP_DST_0 (MAP_DST_0 Pipe 0 VC): 0x0
0x04,0x4E,0x09,0x0F,0x00, // MIPI_TX__0 : MIPI_TX15 | (Default) MAP_SRC_1 (MAP_SRC_1 Pipe 0 DT): 0x0 | (Default) MAP_SRC_1 (MAP_SRC_1 Pipe 0 VC): 0x0
0x04,0x4E,0x09,0x10,0x00, // MIPI_TX__0 : MIPI_TX16 | (Default) MAP_DST_1 (MAP_DST_1 Pipe 0 DT): 0x0 | (Default) MAP_DST_1 (MAP_DST_1 Pipe 0 VC): 0x0
0x04,0x4E,0x09,0x11,0x00, // MIPI_TX__0 : MIPI_TX17 | (Default) MAP_SRC_2 (MAP_SRC_2 Pipe 0 DT): 0x0 | (Default) MAP_SRC_2 (MAP_SRC_2 Pipe 0 VC): 0x0
0x04,0x4E,0x09,0x12,0x00, // MIPI_TX__0 : MIPI_TX18 | (Default) MAP_DST_2 (MAP_DST_2 Pipe 0 DT): 0x0 | (Default) MAP_DST_2 (MAP_DST_2 Pipe 0 VC): 0x0
0x04,0x4E,0x09,0x4B,0x00, // MIPI_TX__1 : MIPI_TX11 | (Default) MAP_EN_L (MAP_EN_L Pipe 1): 0x0
0x04,0x4E,0x09,0x4C,0x00, // MIPI_TX__1 : MIPI_TX12 | (Default) MAP_EN_H (MAP_EN_H Pipe 1): 0x0
0x04,0x4E,0x09,0x4D,0x00, // MIPI_TX__1 : MIPI_TX13 | (Default) MAP_SRC_0 (MAP_SRC_0 Pipe 1 DT): 0x0 | (Default) MAP_SRC_0 (MAP_SRC_0 Pipe 1 VC): 0x0
0x04,0x4E,0x09,0x4E,0x00, // MIPI_TX__1 : MIPI_TX14 | (Default) MAP_DST_0 (MAP_DST_0 Pipe 1 DT): 0x0 | (Default) MAP_DST_0 (MAP_DST_0 Pipe 1 VC): 0x0
0x04,0x4E,0x09,0x4F,0x00, // MIPI_TX__1 : MIPI_TX15 | (Default) MAP_SRC_1 (MAP_SRC_1 Pipe 1 DT): 0x0 | (Default) MAP_SRC_1 (MAP_SRC_1 Pipe 1 VC): 0x0
0x04,0x4E,0x09,0x50,0x00, // MIPI_TX__1 : MIPI_TX16 | (Default) MAP_DST_1 (MAP_DST_1 Pipe 1 DT): 0x0 | (Default) MAP_DST_1 (MAP_DST_1 Pipe 1 VC): 0x0
0x04,0x4E,0x09,0x51,0x00, // MIPI_TX__1 : MIPI_TX17 | (Default) MAP_SRC_2 (MAP_SRC_2 Pipe 1 DT): 0x0 | (Default) MAP_SRC_2 (MAP_SRC_2 Pipe 1 VC): 0x0
0x04,0x4E,0x09,0x52,0x00, // MIPI_TX__1 : MIPI_TX18 | (Default) MAP_DST_2 (MAP_DST_2 Pipe 1 DT): 0x0 | (Default) MAP_DST_2 (MAP_DST_2 Pipe 1 VC): 0x0
0x04,0x4E,0x09,0x2D,0x00, // MIPI_TX__0 : MIPI_TX45 | MAP_DPHY_DEST_0 (MAP_DPHY_DST_0 Pipe 0): 0x0 | MAP_DPHY_DEST_1 (MAP_DPHY_DST_1 Pipe 0): 0x0 | MAP_DPHY_DEST_2 (MAP_DPHY_DST_2 Pipe 0): 0x0
0x04,0x4E,0x09,0x6D,0x00, // MIPI_TX__1 : MIPI_TX45 | MAP_DPHY_DEST_0 (MAP_DPHY_DST_0 Pipe 1): 0x0 | MAP_DPHY_DEST_1 (MAP_DPHY_DST_1 Pipe 1): 0x0 | MAP_DPHY_DEST_2 (MAP_DPHY_DST_2 Pipe 1): 0x0
// Double Mode Configuration
// MIPI DPHY Configuration
0x04,0x4E,0x08,0xA0,0x04, // MIPI_PHY : MIPI_PHY0 | (Default) phy_4x2 (Port Configuration): 2 (1x4)
0x04,0x4E,0x09,0x4A,0xD0, // MIPI_TX__1 : MIPI_TX10 | (Default) CSI2_LANE_CNT (Port A - Lane Count): 4
0x04,0x4E,0x08,0xA3,0xE4, // MIPI_PHY : MIPI_PHY3 | (Default) phy0_lane_map (Lane Map - PHY0 D0): Lane 0 | (Default) phy0_lane_map (Lane Map - PHY0 D1): Lane 1 | (Default) phy1_lane_map (Lane Map - PHY1 D0): Lane 2 | (Default) phy1_lane_map (Lane Map - PHY1 D1): Lane 3
0x04,0x4E,0x08,0xA5,0x00, // MIPI_PHY : MIPI_PHY5 | (Default) phy0_pol_map (Polarity - PHY0 Lane 0): Normal | (Default) phy0_pol_map (Polarity - PHY0 Lane 1): Normal | (Default) phy1_pol_map (Polarity - PHY1 Lane 0): Normal | (Default) phy1_pol_map (Polarity - PHY1 Lane 1): Normal | (Default) phy1_pol_map (Polarity - PHY1 Clock Lane): Normal
0x04,0x4E,0x09,0x43,0x07, // MIPI_TX__1 : MIPI_TX3 | DESKEW_INIT (Controller 1 Auto Initial Deskew): Disabled
0x04,0x4E,0x09,0x44,0x01, // MIPI_TX__1 : MIPI_TX4 | DESKEW_PER (Controller 1 Periodic Deskew): Disabled
0x04,0x4E,0x1D,0x00,0xF4, //  (config_soft_rst_n - PHY1): 0x0
// MIPI DPHY Configuration
0x04,0x4E,0x09,0x8A,0xD0, // MIPI_TX__2 : MIPI_TX10 | (Default) CSI2_LANE_CNT (Port B - Lane Count): 4
0x04,0x4E,0x08,0xA4,0xE4, // MIPI_PHY : MIPI_PHY4 | (Default) phy2_lane_map (Lane Map - PHY2 D0): Lane 0 | (Default) phy2_lane_map (Lane Map - PHY2 D1): Lane 1 | (Default) phy3_lane_map (Lane Map - PHY3 D0): Lane 2 | (Default) phy3_lane_map (Lane Map - PHY3 D1): Lane 3
0x04,0x4E,0x08,0xA6,0x00, // MIPI_PHY : MIPI_PHY6 | (Default) phy2_pol_map (Polarity - PHY2 Lane 0): Normal | (Default) phy2_pol_map (Polarity - PHY2 Lane 1): Normal | (Default) phy3_pol_map (Polarity - PHY3 Lane 0): Normal | (Default) phy3_pol_map (Polarity - PHY3 Lane 1): Normal | (Default) phy2_pol_map (Polarity - PHY2 Clock Lane): Normal
0x04,0x4E,0x09,0x83,0x07, // MIPI_TX__2 : MIPI_TX3 | DESKEW_INIT (Controller 2 Auto Initial Deskew): Disabled
0x04,0x4E,0x09,0x84,0x01, // MIPI_TX__2 : MIPI_TX4 | DESKEW_PER (Controller 2 Periodic Deskew): Disabled
0x04,0x4E,0x1E,0x00,0xF4, //  (config_soft_rst_n - PHY2): 0x0
// This is to set predefined (coarse) CSI output frequency
// CSI Phy 1 is 1500 Mbps/lane.
0x04,0x4E,0x1D,0x00,0xF4, // (Default)
0x04,0x4E,0x04,0x18,0x2F, // (Default)
0x04,0x4E,0x1D,0x00,0xF5, //  | (Default)  (config_soft_rst_n - PHY1): 0x1
// CSI Phy 2 is 1500 Mbps/lane.
0x04,0x4E,0x1E,0x00,0xF4, // (Default)
0x04,0x4E,0x04,0x1B,0x2F, // (Default)
0x04,0x4E,0x1E,0x00,0xF5, //  | (Default)  (config_soft_rst_n - PHY2): 0x1
0x04,0x4E,0x08,0xA2,0xF4, // MIPI_PHY : MIPI_PHY2 | phy_Stdby_n (phy_Stdby_0)
0x04,0x4E,0x04,0x0B,0x02, // BACKTOP : BACKTOP12 | CSI_OUT_EN (CSI_OUT_EN): CSI output enabled
