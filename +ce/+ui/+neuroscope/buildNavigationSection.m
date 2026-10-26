function [panel,controls]=buildNavigationSection(parent,settings,callbacks)
%BUILDNAVIGATIONSECTION Preserve the original compact navigation arrangement.
% Its 65-pixel section height is included in the measured sidebar scroll total.
panel=uipanel('Parent',parent,'Title','Navigation');
controls.main=panel;
controls.play1=button([0.01 0.01 0.15 0.98],char(9654),callbacks.play,'Stream from current timepoint');
controls.back=button([0.17 0.01 0.15 0.98],char(8592),callbacks.back,'Go back in time');
controls.increaseAmplitude=button([0.33 0.5 0.34 0.49],char(8593),callbacks.increaseAmplitude,'Increase amplitude of ephys data');
controls.decreaseAmplitude=button([0.33 0.01 0.34 0.49],char(8595),callbacks.decreaseAmplitude,'Decrease amplitude of ephys data');
controls.advance=button([0.68 0.01 0.15 0.98],char(8594),callbacks.advance,'Forward in time');
controls.play2=button([0.84 0.01 0.15 0.98],[char(9655) char(9654)],callbacks.playEnd,'Stream from end of file');
    function control=button(position,label,callback,tooltip)
        control=uicontrol('Parent',panel,'Style','pushbutton','Units','normalized', ...
            'Position',position,'String',label,'Callback',callback, ...
            'KeyPressFcn',callbacks.keyPress,'TooltipString',tooltip,'FontSize',settings.fontsize);
    end
end
