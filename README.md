# signal_generator
simple signal generator implemnted on microcontroller 
Creating a simple function generator, that can output three types of signals, in frequencys between 1-999 Hz
The user will operate the signal generator by sending via the UART a four character string. The first character
will be an ‘S’ (Sine) or an  ‘A’ (sAwtooth), or an ‘Q’ (sQuare). The next three characters
will be a three frequency value. for exsample to have the signal generator output a
500 Hz sin wave, the user will type S500.
