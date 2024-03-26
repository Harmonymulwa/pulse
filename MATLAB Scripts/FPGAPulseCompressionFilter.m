
% -------------------
% This script shows the general concept of a pulse compression filter.
% Appart from the signal generation and the usage of FIR and complex FIR
% filter (achived through conv()), the designed script is near ideantical
% to the FPGA design.
%


% Clear any saved vairable from MATLAB's workspace section.
clear all



%%
% Creating the input data and the matched filter impulse response signal.
% These signals are saved to a MIF file will then be loaded to the FPGA.


% Setting the cirp waveform start and end frequency, as well as its
% duration and the sampling frequency.
chirpFreqStart = 1e6;   %1MHz
chirpFreqEnd = 10e6;    %10MHz
chirpDuration = 10e-6;  %10uS
samplingFreqs = 80e6;   %80MHz


% Sampling frequency of samplingFreqs for chirpDuration duration.
tChirp = 0:1/samplingFreqs:chirpDuration-1/samplingFreqs;
% Creating the time scale for x_t, this is used when plotting the graph.
tInput = 0:1/samplingFreqs:(chirpDuration * 18) -1/samplingFreqs;
% Creating the time scale for y_t.
tOut = 0:1/samplingFreqs:(chirpDuration * 19) -1/samplingFreqs;


% Creating a linear chirp waveform
chirpWave = chirp(tChirp,chirpFreqStart,chirpDuration,chirpFreqEnd);


% Creating padding of zeros before and after the chirp wave. These
% paddings are of duration equivalent to the length of chirpWave and consists of
% amplitude reduction of 0.9, 0.8, 0.7, and 0.6.
paddedChirpWaveAmp1   = [zeros(1,length(chirpWave)), chirpWave * 1.0, zeros(1,length(chirpWave))];
paddedChirpWaveAmp0_9 = [zeros(1,length(chirpWave)), chirpWave * 0.9, zeros(1,length(chirpWave))];
paddedChirpWaveAmp0_8 = [zeros(1,length(chirpWave)), chirpWave * 0.8, zeros(1,length(chirpWave))];
paddedChirpWaveAmp0_7 = [zeros(1,length(chirpWave)), chirpWave * 0.7, zeros(1,length(chirpWave))];
paddedChirpWaveAmp0_6 = [zeros(1,length(chirpWave)), chirpWave * 0.6, zeros(1,length(chirpWave))];


% Creating chirp signals with different amount of noise.
chirp1 = awgn(paddedChirpWaveAmp1, 25,1,1);
chirp2 = awgn(paddedChirpWaveAmp0_9,15,1,1);
chirp3 = awgn(paddedChirpWaveAmp0_8,10,1,1);
chirp4 = awgn(paddedChirpWaveAmp0_7,5,1,1);
chirp5 = awgn(paddedChirpWaveAmp0_6,0.001,1,1);
chirp6 = awgn(paddedChirpWaveAmp1,-5,1,1);


% Summing up the different chirp waveforms into one continous long input signal.
receivedSignalNoNoise = [paddedChirpWaveAmp1, paddedChirpWaveAmp0_9, ...
                         paddedChirpWaveAmp0_8, paddedChirpWaveAmp0_7, ...
                         paddedChirpWaveAmp0_6, paddedChirpWaveAmp1];
receivedSignal = [chirp1, chirp2, chirp3, chirp4, chirp5, chirp6];


% Multiplying and rounding the receivedSignal so that the aquired signal in
% FPGA can be comfirmed with the MATLAB results.
receivedSignal = round(receivedSignal * 204);


% Creating the matched filter impulse response. This is equal to the complex
% conjugate time reverse analytic signal of the chirp signal. Its
% muiltiplied by 1451 and rounded so that the results from FPGA can be
% comfirmed in MATLAB.
h_t = round(flip(conj(hilbert(chirpWave)))* 1451);



%%
% Main opperation that is implimented copied from the FPGA.


% Creating the hilbert transform coefficients. This uses the firpm function
% to create the HTCoeff array. Every second coefficient should be 0,
% however due to the muiltiplication by 3200, some coefficients end up 1
% or -1, hence have been changed to 0.
% HTCoeff = round(firpm(26,[0.1 0.9],[1 1],'hilbert') * 3200);
HTCoeff = [-25 0 -51 0  -100 0 -181 0 -321 0 -624 0 -2018 0 2018 0 624 0 321 0 181 0 100 0 51 0 25];


% Creating the complex input signal.
x_t_real = receivedSignal;
x_t_imag = conv(HTCoeff, receivedSignal);
x_t = complex(x_t_real, x_t_imag(1:length(x_t_real)));
% x_t = hilbert(receivedSignal);


% The matched filter opperation is a convelution between the input signal
% and the matched filters impulse reponse.
matchedFilterOut = conv(x_t,h_t);


% Obtaining the envelop value of the matched filter output.
%y_t = abs(matchedFilterOut);
y_t = [];
for i = 1:1:(length(matchedFilterOut))
    realValueSquared = real(matchedFilterOut(i))*real(matchedFilterOut(i));
    imagValueSquared = imag(matchedFilterOut(i))*imag(matchedFilterOut(i));
    squarValue = squareRootCal(realValueSquared + imagValueSquared);

    squarBinValue = dec2bin(squarValue,42);
    y_t = [y_t bin2dec(squarBinValue(end-41:end-10))];
end



%%
% Plotting the following graphs:
%    Chirp waveform
%    Received echoed back signal with no noise
%    Received echoed back signal with noise

figure(1)
tiledlayout(3,1);

nexttile
plot(tChirp,chirpWave)
title('Liniear Chirp Waveform from 1MHz to 10MHz')
ylabel('Amplitude')
xlabel('Time (S)')


nexttile
plot(tInput,receivedSignalNoNoise)
title('Echoed back signal from the receiver with no noise')
ylabel('Amplitude')
xlabel('Time (S)')


nexttile
plot(tInput,receivedSignal)
title('Echoed back signal from the receiver with noise')
ylabel('Amplitude')
xlabel('Time (S)')



%%
% Plotting the following graphs:
%    Real part of the received after the hilbert transform
%    Imaginary part of the received after the hilbert transform
%    Real part of the matched filter impulse response after the hilbert transform
%    Imaginary part of the matched filter impulse response after the hilbert transform
%    Pulse compression filter output waveform

figure(2)
tiledlayout(3,2);

nexttile
plot(tInput,real(x_t))
title('Real part of the recivied signal XRe(t)')
ylabel('Amplitude')
xlabel('Time (S)')


nexttile
plot(tInput,imag(x_t))
title('Imaginary part of the recivied signal XIm(t)')
ylabel('Amplitude')
xlabel('Time (S)')


nexttile
plot(tChirp,real(h_t))
title('Real part of the impulse reponse hRe(t)')
ylabel('Amplitude')
xlabel('Time (S)')


nexttile
plot(tChirp,imag(h_t))
title('Imaginary part of the recivied signal hIm(t)')
ylabel('Amplitude')
xlabel('Time (S)')


nexttile([1 2])
plot(tOut(1:end-1),y_t)
title('Matched filter output y(t)')
ylabel('Magnitude')
xlabel('Time (S)')



%%
% The following section is for the creation of the h_t, x_t and, y_t MIF files.
% The files are created in this section as AWGN adds different kind of noise
% everysingle time. Hence to compare the MATLAB and FPGA results the MIF files
% must be generatered in this script.



% Name of the MIF file.
MIFFile = 'MFImpulseCoeff.mif';

% Create or open (if file already exsists) the MIF file.
fileID = fopen(MIFFile,'w');


% Print the coefficients (h_t) to the MIF file. The values that are printed
% are the rounded real and imaginary parts. They are printed in 2's
% compliment format. The length of each value is 16 bits.
for i = 1:1:length(h_t)
    binRealh_t = dec2bin(round(real(h_t(i))),16);
    binImagh_t = dec2bin(round(imag(h_t(i))),16);

    fprintf(fileID,'%s\n', binRealh_t(end-11:end));
    fprintf(fileID,'%s\n', binImagh_t(end-11:end));
end


% Close the opened MIF file.
fclose(fileID);





% Name of the MIF file.
MIFFile = 'MFInputData.mif';

% Create or open (if file already exsists) the MIF file.
fileID = fopen(MIFFile,'w');


% Print the input data (x_t) to the MIF file. The values that are printed
% are the rounded to int values. They are printed in 2's
% compliment format. The length of each value is 16 bits.
for i = 1:1:length(receivedSignal)
    binReceivedSignal = dec2bin(round(receivedSignal(i)),16);

    fprintf(fileID,'%s\n', binReceivedSignal(end-11:end));
end

% Close the opened MIF file.
fclose(fileID);






% Name of the MIF file.
MIFFile = 'MFOutputData.mif';

% Create or open (if file already exsists) the MIF file.
fileID = fopen(MIFFile,'w');


% Print the output data (y_t) to the MIF file. They are printed in 2's
% compliment format, with the length of each value being 32 bits.
for i = 1:1:length(x_t)
    % Make the values first 52 bits long then trim it to 32. This is dones
    % as MATLAB for some values just adds 10 or so 0's for no reason with
    % some values. Hence the trimming.
    binReceivedSignal = dec2bin(y_t(i),52);

    fprintf(fileID,'%s\n', binReceivedSignal(end-31:end));
end

% Close the opened MIF file.
fclose(fileID);
