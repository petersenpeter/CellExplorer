
basepath = 'Z:\Homes\peterp03\IntanData\MS22\Peter_MS22_180626_110916_concat';
cd(basepath)
session = loadSession(basepath); % Loading session info

%% Importing wheel data
wheel = intan2buzcode('session',session,'dataName','WheelPosition','data_source_type','adc','container_type','behavior','processing','wheel_position','downsample_samples',200); % Loads wheel data

%% Importing temperature data
temperature = intan2buzcode('session',session,'dataName','Temperature','container_type','timeseries','processing','thermocouple');

%% Plotting 
figure, 
subplot(2,1,1)
plot(wheel.timestamps,abs(wheel.velocity))
subplot(2,1,2)
plot(temperature.timestamps,temperature.data)

temp_lowsampled = interp1(temperature.timestamps,temperature.data,wheel.timestamps);
figure,
plot(abs(wheel.velocity),temp_lowsampled,'.')
