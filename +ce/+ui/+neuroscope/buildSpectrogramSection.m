function [section,controls]=buildSpectrogramSection(parent,settings,callback)
%BUILDSPECTROGRAMSECTION Labeled spectral settings without manual geometry.
section=ce.ui.layout.RowSection(parent,'Spectrogram',settings.fontsize);
controls.main=section.Panel;
controls.showSpectrogram=section.addControl('show','checkbox','String','Show spectrogram','Value',0,'Callback',callback);
controls.spectrogramChannel=section.addField('channel','Channel','edit','String',num2str(settings.spectrogram.channel),'Callback',callback);
controls.spectrogramWindow=section.addField('window','Window width (s)','edit','String',num2str(settings.spectrogram.window),'Callback',callback);
controls.freq_low=section.addField('low','Low frequency (Hz)','edit','String',num2str(settings.spectrogram.freq_low),'Callback',callback);
controls.freq_step_size=section.addField('step','Frequency step (Hz)','edit','String',num2str(settings.spectrogram.freq_step_size),'Callback',callback);
controls.freq_high=section.addField('high','High frequency (Hz)','edit','String',num2str(settings.spectrogram.freq_high),'Callback',callback);
end
