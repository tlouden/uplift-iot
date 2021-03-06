EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "UPLIFT Desk IoT Inline"
Date ""
Rev "2"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector:RJ45 J1
U 1 1 6133FFC0
P 1200 1400
F 0 "J1" H 1257 2067 50  0000 C CNN
F 1 "RJ45" H 1257 1976 50  0000 C CNN
F 2 "Connector_RJ:RJ45_Amphenol_54602-x08_Horizontal" V 1200 1425 50  0001 C CNN
F 3 "~" V 1200 1425 50  0001 C CNN
	1    1200 1400
	1    0    0    -1  
$EndComp
$Comp
L Connector:RJ45 J2
U 1 1 61341F55
P 1200 2800
F 0 "J2" H 1257 3467 50  0000 C CNN
F 1 "RJ45" H 1257 3376 50  0000 C CNN
F 2 "Connector_RJ:RJ45_Amphenol_54602-x08_Horizontal" V 1200 2825 50  0001 C CNN
F 3 "~" V 1200 2825 50  0001 C CNN
	1    1200 2800
	1    0    0    -1  
$EndComp
$Comp
L Device:R R2
U 1 1 6134359F
P 1850 4000
F 0 "R2" H 1920 4046 50  0000 L CNN
F 1 "2k2" H 1920 3955 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 1780 4000 50  0001 C CNN
F 3 "~" H 1850 4000 50  0001 C CNN
	1    1850 4000
	1    0    0    -1  
$EndComp
$Comp
L Device:R R3
U 1 1 61343F6C
P 1850 4500
F 0 "R3" H 1920 4546 50  0000 L CNN
F 1 "4k7" H 1920 4455 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 1780 4500 50  0001 C CNN
F 3 "~" H 1850 4500 50  0001 C CNN
	1    1850 4500
	1    0    0    -1  
$EndComp
$Comp
L Device:R R1
U 1 1 613443DC
P 950 4000
F 0 "R1" H 1020 4046 50  0000 L CNN
F 1 "100" H 1020 3955 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 880 4000 50  0001 C CNN
F 3 "~" H 950 4000 50  0001 C CNN
	1    950  4000
	1    0    0    -1  
$EndComp
$Comp
L Device:Speaker LS1
U 1 1 61344E52
P 1150 4300
F 0 "LS1" H 1320 4296 50  0000 L CNN
F 1 "Speaker" H 1320 4205 50  0000 L CNN
F 2 "Buzzer_Beeper:MagneticBuzzer_ProSignal_ABT-410-RC" H 1150 4100 50  0001 C CNN
F 3 "~" H 1140 4250 50  0001 C CNN
	1    1150 4300
	1    0    0    -1  
$EndComp
Wire Wire Line
	1600 1700 1650 1700
Wire Wire Line
	1650 1700 1650 3100
Wire Wire Line
	1650 3100 1600 3100
Wire Wire Line
	1600 1600 1700 1600
Wire Wire Line
	1700 1600 1700 3000
Wire Wire Line
	1700 3000 1600 3000
Wire Wire Line
	1600 2900 1750 2900
Wire Wire Line
	1750 2900 1750 1500
Wire Wire Line
	1750 1500 1600 1500
Wire Wire Line
	1600 1400 1800 1400
Wire Wire Line
	1800 1400 1800 2800
Wire Wire Line
	1800 2800 1600 2800
Wire Wire Line
	1600 2700 1850 2700
Wire Wire Line
	1850 2700 1850 1300
Wire Wire Line
	1850 1300 1600 1300
Wire Wire Line
	1600 1200 1900 1200
Wire Wire Line
	1900 1200 1900 2600
Wire Wire Line
	1900 2600 1600 2600
Wire Wire Line
	1600 2500 1950 2500
Wire Wire Line
	1950 2500 1950 1100
Wire Wire Line
	1950 1100 1600 1100
Wire Wire Line
	1600 1000 2000 1000
Wire Wire Line
	2000 1000 2000 2400
Wire Wire Line
	2000 2400 1600 2400
$Comp
L power:GND #PWR0101
U 1 1 6134CAC0
P 1750 3300
F 0 "#PWR0101" H 1750 3050 50  0001 C CNN
F 1 "GND" H 1755 3127 50  0000 C CNN
F 2 "" H 1750 3300 50  0001 C CNN
F 3 "" H 1750 3300 50  0001 C CNN
	1    1750 3300
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0102
U 1 1 6134D9F4
P 1850 4750
F 0 "#PWR0102" H 1850 4500 50  0001 C CNN
F 1 "GND" H 1855 4577 50  0000 C CNN
F 2 "" H 1850 4750 50  0001 C CNN
F 3 "" H 1850 4750 50  0001 C CNN
	1    1850 4750
	1    0    0    -1  
$EndComp
Wire Wire Line
	1750 2900 1750 3300
Connection ~ 1750 2900
$Comp
L power:+5V #PWR0104
U 1 1 6134F994
P 1850 3100
F 0 "#PWR0104" H 1850 2950 50  0001 C CNN
F 1 "+5V" H 1865 3273 50  0000 C CNN
F 2 "" H 1850 3100 50  0001 C CNN
F 3 "" H 1850 3100 50  0001 C CNN
	1    1850 3100
	-1   0    0    1   
$EndComp
$Comp
L power:+5V #PWR0105
U 1 1 61350872
P 2750 950
F 0 "#PWR0105" H 2750 800 50  0001 C CNN
F 1 "+5V" H 2765 1123 50  0000 C CNN
F 2 "" H 2750 950 50  0001 C CNN
F 3 "" H 2750 950 50  0001 C CNN
	1    2750 950 
	0    -1   -1   0   
$EndComp
Wire Wire Line
	1850 2700 1850 3100
Connection ~ 1850 2700
Text GLabel 2100 3000 2    50   Input ~ 0
uart_data
Wire Wire Line
	1700 3000 2100 3000
Connection ~ 1700 3000
Text GLabel 2250 3750 2    50   Input ~ 0
uart_data
Wire Wire Line
	1850 3750 2250 3750
$Comp
L power:GND #PWR0106
U 1 1 61358CE6
P 950 4550
F 0 "#PWR0106" H 950 4300 50  0001 C CNN
F 1 "GND" H 955 4377 50  0000 C CNN
F 2 "" H 950 4550 50  0001 C CNN
F 3 "" H 950 4550 50  0001 C CNN
	1    950  4550
	1    0    0    -1  
$EndComp
Wire Wire Line
	1850 3750 1850 3850
Wire Wire Line
	1850 4650 1850 4750
Connection ~ 1850 4250
Wire Wire Line
	1850 4250 1850 4150
Wire Wire Line
	1850 4350 1850 4250
Wire Wire Line
	2250 4250 1850 4250
Text GLabel 2250 4250 2    50   Input ~ 0
esp32_rx2
Text GLabel 4250 2150 2    50   Input ~ 0
esp32_rx2
$Comp
L power:GND #PWR0107
U 1 1 613673A4
P 3650 3850
F 0 "#PWR0107" H 3650 3600 50  0001 C CNN
F 1 "GND" H 3655 3677 50  0000 C CNN
F 2 "" H 3650 3850 50  0001 C CNN
F 3 "" H 3650 3850 50  0001 C CNN
	1    3650 3850
	0    -1   -1   0   
$EndComp
Text GLabel 4250 2050 2    50   Input ~ 0
speaker
Text GLabel 1250 3750 2    50   Input ~ 0
speaker
Wire Wire Line
	950  4400 950  4550
Wire Wire Line
	950  4300 950  4150
Wire Wire Line
	1250 3750 950  3750
Wire Wire Line
	950  3750 950  3850
$Comp
L ESP32_DevKit_V1_DOIT:ESP32_DevKit_V1_DOIT U1
U 1 1 6136C14B
P 3550 2350
F 0 "U1" H 3550 3931 50  0000 C CNN
F 1 "ESP32_DevKit_V1_DOIT" H 3550 3840 50  0000 C CNN
F 2 "ESP32_DevKit_V1_DOIT:esp32_devkit_v1_doit" H 3100 3700 50  0001 C CNN
F 3 "https://aliexpress.com/item/32864722159.html" H 3100 3700 50  0001 C CNN
	1    3550 2350
	1    0    0    -1  
$EndComp
Wire Wire Line
	4150 2150 4250 2150
Wire Wire Line
	3650 3850 3550 3850
Wire Wire Line
	3550 3850 3550 3750
Wire Wire Line
	3450 3750 3450 3850
Wire Wire Line
	3450 3850 3550 3850
Connection ~ 3550 3850
Wire Wire Line
	4250 2050 4150 2050
Wire Wire Line
	3450 950  2750 950 
$EndSCHEMATC
