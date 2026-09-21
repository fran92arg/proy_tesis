clear
clc
close all
%% rutas relativaas
% scriptDir   = fileparts(mfilename('fullpath'));
rutaScripts   = fileparts(mfilename('fullpath')); %me da la ruta actual del script que ejecuto
raizProy = fileparts(rutaScripts); %subo un nivel de la carpeta que obtuve antes
rutaData     = fullfile(projectRoot, 'data');
rutaResult  = fullfile(projectRoot, 'results');
eeglabRoot  = fullfile(projectRoot, 'eeglab');
%% Cargar
EEG = pop_biosig('...\data\LUI14071945017');
EEG=eeg_checkset(EEG);%verificar consistencia de la estructura
f_muestreo=EEG.srate;
%eeglab redraw
%% butterworth pasaalto
EEG=pasaalto(EEG);
% t=EEG.times;
% eeg_filt_hp=zeros(size(EEG.data));
% fs=0.05; %frecuencia inicio banda de rechazo
% fp=0.5; %frecuencia inicio banda de paso
% ws=fs/(f_muestreo/2);
% wp=fp/(f_muestreo/2);
% [N,wn]=buttord(wp,ws,1,40); %%atenuación en la banda de paso y rechazo
% [num,den]=butter(N,wn,'high'); %Coef de FT
% figure(1)
% title('Respuesta en frecuencia filtro pasaaltos')
% freqz(num,den,2048,256);
% figure(1)
% title('Respuesta en frecuencia filtro pasaaltos')
% freqz(pasaalto,2048,256);
% for i=1:EEG.nbchan
%     eeg_filt_hp(i,:)=filter(pasaalto,double(EEG.data(i,:))); 
% end
 %figure(2);
% %pwelch(eeg_filt_hp(5,:),hanning(1024),[], 2048,256); %senal de entrada, ventana(resolucion espectral o no me acuerdo),no superposiciónd de ventanas,cant de puntos,f muestreo señal
% periodogram(eeg_filt_hp(5,:),[],1024,256)
% hold on;
% %pwelch(EEG.data(5,:),hanning(1024),[],2048,256);
% periodogram(EEG.data(5,:),[],1024,256)

%% Pasabajos
EEG=pasabajo(EEG);
% fs1=105;
% fp1=100;
% wspb=fs1/(f_muestreo/2);
% wppb=fp1/(f_muestreo/2);
% [N1,wn1]=buttord(wppb,wspb,1,10);
% [num1,den1]=butter(N1,wn1,'low');

% eeg_filt_lp=zeros(size(EEG.data));
% figure(2)
% title('Respuesta en frecuencia filtro pasabajos')
% freqz(pasabajo,2048,256);
% for i=1:EEG.nbchan
%     eeg_filt_lp(i,:)=filter(pasabajo,double(eeg_filt_hp(i,:)));
% end
% figure(3);
% %pwelch(eeg_filt_lp(5,:),hanning(1024),[], 2048,256); %señal de entrada, ventana(resolucion espectral o no me acuerdo),no superposiciónd de ventanas,cant de puntos,f muestreo señal
% periodogram(eeg_filt_lp(5,:),[],1024,256)
% 
% hold on;
% %pwelch(EEG.data(5,:),hanning(1024),[],2048,256);
% periodogram(EEG.data(5,:),[],1024,256)

%%
% EEG.data= eeg_filt_lp;
% EEG=pop_saveset(EEG,'moreno_filtradoPasaaltobajo.set','C:\Users\natyr\OneDrive\Escritorio')

%% Filtro notch 50Hz
EEG=notch(EEG);
% flinea=50;
% angulo=(flinea*90)/(f_muestreo/4);
% z1=cos(angulo)+j*sin(angulo);
% z2=conj(z1);
% zpk([z1 z2],[],1)
% num_ranura=[1 -(z1+z2) z1*z2]
% den_ranura=1;
%zplane(num_ranura,den_ranura);
% BW     = 2;   % Bandwidth
% Apass  = 1;   % Bandwidth Attenuation
% 
% [b, a] = iirnotch(Fnotch/(Fs/2), BW/(Fs/2), Apass);
% Hd     = dfilt.df2(b, a);
% eeg_filt_ranura=zeros(size(EEG.data));
% for i=1:EEG.nbchan
%     % eeg_filt_ranura(i,:)=filter(num_ranura,den_ranura,double(eeg_filt_lp(i,:)));
%     eeg_filt_ranura(i,:)=filter(notch,double(eeg_filt_lp(i,:)));
% end
% figure(4)
% freqz(notch)
% title('Rta. módulo y fase - notch 50 Hz, fs=256 Hz')
% figure(5);
% %pwelch(eeg_filt_ranura(1,:),hanning(1024),[], 2048,256); %señal de entrada, ventana(resolucion espectral o no me acuerdo),no superposiciónd de ventanas,cant de puntos,f muestreo señal
% periodogram(eeg_filt_ranura(1,:),[],1024,256)
% hold on;
% %pwelch(EEG.data(1,:),hanning(1024),[],2048,256);
% periodogram(EEG.data(1,:),[],1024,256)

%%
% eeg_filt_ranura100=zeros(size(EEG.data));
% for i=1:EEG.nbchan
%     % eeg_filt_ranura(i,:)=filter(num_ranura,den_ranura,double(eeg_filt_lp(i,:)));
%     eeg_filt_ranura100(i,:)=filter(notch100,double(eeg_filt_ranura(i,:)));
% end
% figure(5)
% freqz(notch100)
% title('Rta. módulo y fase - notch 100 Hz, fs=256 Hz')
% figure(6);
% %pwelch(eeg_filt_ranura100(1,:),hanning(1024),[], 2048,256); %señal de entrada, ventana(resolucion espectral o no me acuerdo),no superposiciónd de ventanas,cant de puntos,f muestreo señal
% periodogram(eeg_filt_ranura100(1,:),[],1024,256)
% 
% hold on;
% %pwelch(EEG.data(1,:),hanning(1024),[],2048,256);
% periodogram(EEG.data(1,:),[],1024,256)

%%
% EEG.data= eeg_filt_ranura100;
% EEG=eeg_checkset(EEG)
% EEG=pop_saveset(EEG,'moreno_filtradonotch.set','C:\Users\natyr\OneDrive\Escritorio')

% %% Cleanline
% EEG = pop_cleanline(EEG, 'bandwidth', 1, ...
%     'chanlist', 1, ... %canales EEG, excluyendo el EKG
%     'computepower', 1, ...
%     'linefreqs', [50 100], ... % o [50 100] para incluir el armónico
%     'normSpectrum', 0, ...
%     'p', 0.01, ...
%     'plotfigures', 0, ...
%     'scanforlines', 1, ...
%     'sigtype', 'Channels', ...
%     'tau', 100, ...
%     'verb', 1, ...
%     'winsize', 6, ...
%     'winstep', 1);
% EEG=eeg_checkset(EEG)
% EEG=pop_saveset(EEG,'moreno_filtradocleanline.set','C:\Users\natyr\OneDrive\Escritorio')
% figure(4)
% %pwelch(EEG.data(1,:),hanning(1024),[], 2048,256); %señal de entrada, ventana(resolucion espectral o no me acuerdo),no superposiciónd de ventanas,cant de puntos,f muestreo señal
% periodogram(EEG.data(1,:),[],1024,256)
% 
% hold on;
% %pwelch(eeg_filt_lp(1,:),hanning(1024),[],2048,256);
% periodogram(eeg_filt_lp(1,:),[],1024,256)

%% ICA
EEG=ICA(EEG)


