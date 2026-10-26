function tests=testRowLayout
tests=functiontests(localfunctions);
end
function setup(t)
root=fileparts(fileparts(mfilename('fullpath')));
t.TestData.oldPath=path; addpath(root); addpath(fullfile(root,'toolboxes','GUI Layout Toolbox 2.3.5'));
f=figure('Visible','off','Position',[100 100 360 700]); t.TestData.figure=f;
scroll=uix.ScrollingPanel('Parent',f); stack=uix.VBox('Parent',scroll,'Padding',3,'Spacing',5);
section=ce.ui.layout.RowSection(stack,'Test section',10);
t.TestData.section=section; t.TestData.stack=stack; t.TestData.scroll=scroll;
t.TestData.listener=ce.ui.layout.bindSection(section,stack,scroll); f.Visible='on'; settle(t);
end
function teardown(t)
delete(t.TestData.figure); path(t.TestData.oldPath);
end
function testAddingFieldUpdatesParentAndScrollWithoutDimensions(t)
s=t.TestData.section; before=t.TestData.scroll.MinimumHeights;
field=s.addField('gain','Gain','edit','String','10'); settle(t);
verifyGreaterThan(t,t.TestData.scroll.MinimumHeights,before);
verifyEqual(t,t.TestData.stack.Heights,s.PreferredHeight);
verifyEqual(t,t.TestData.stack.MinimumHeights,s.PreferredHeight);
verifyEqual(t,t.TestData.scroll.MinimumHeights,s.PreferredHeight+6);
verifyEqual(t,field.String,'10');
verifyError(t,@() s.addField('gain','Duplicate','edit'),'ce:ui:DuplicateRow');
end
function testHideCollapseAndRemovePreserveDraftAndReleaseHeight(t)
s=t.TestData.section;
s.addField('first','First','edit','String','1'); field=s.addField('second','Second','edit','String','unsaved'); settle(t);
expanded=s.PreferredHeight;
s.setRowVisible('second',false); settle(t); hidden=s.PreferredHeight;
verifyLessThan(t,hidden,expanded); verifyEqual(t,field.String,'unsaved');
s.setRowVisible('second',true); settle(t); verifyEqual(t,s.PreferredHeight,expanded);
s.setCollapsed(true); settle(t); verifyLessThan(t,s.PreferredHeight,hidden);
s.setCollapsed(false); settle(t); verifyEqual(t,s.PreferredHeight,expanded);
s.removeRow('second'); settle(t); verifyFalse(t,isgraphics(field)); verifyEqual(t,s.PreferredHeight,hidden);
verifyError(t,@() s.removeRow('missing'),'ce:ui:UnknownRow');
end
function testNarrowWidthReflowsWithoutReplacingControls(t)
s=t.TestData.section; field=s.addField('lower','Lower frequency boundary for filtering (Hz)','edit','String','400');
f=t.TestData.figure; f.Position(3)=600; settle(t); wide=s.PreferredHeight;
count=numel(findall(f)); f.Position(3)=230; settle(t);
verifyGreaterThan(t,s.PreferredHeight,wide); verifyTrue(t,isgraphics(field));
verifyEqual(t,field.String,'400');
for i=1:5, f.Position(3)=600; settle(t); f.Position(3)=230; settle(t); end
verifyEqual(t,numel(findall(f)),count);
end
function testFontSizeAndLongLabels(t)
s=t.TestData.section;
field=s.addField('long','A longer field label which must wrap when the sidebar is narrow','edit','String','42');
t.TestData.figure.Position(3)=230; settle(t); normal=s.PreferredHeight;
s.setFontSize(16); settle(t);
verifyGreaterThan(t,s.PreferredHeight,normal); verifyEqual(t,field.FontSize,16);
verifyEqual(t,t.TestData.scroll.MinimumHeights,s.PreferredHeight+6);
end
function testExistingSectionsAndFlexibleMinimaAreIncluded(t)
s=t.TestData.section; s.addField('first','First','edit');
uipanel('Parent',t.TestData.stack); uipanel('Parent',t.TestData.stack);
t.TestData.stack.Heights=[s.PreferredHeight -1 50];
t.TestData.stack.MinimumHeights=[s.PreferredHeight 120 30];
ce.ui.layout.fitScrollingStack(t.TestData.stack,t.TestData.scroll); settle(t);
verifyEqual(t,t.TestData.scroll.MinimumHeights,s.PreferredHeight+120+50+6+10);
s.addField('extra','An optional field','edit','String','5'); settle(t);
verifyEqual(t,t.TestData.scroll.MinimumHeights,s.PreferredHeight+120+50+6+10);
end
function testTraceBuilderKeepsCallbacksAndControls(t)
delete(t.TestData.section);
settings=struct('fontsize',10,'plotStyle',2,'extraSpacing',true,'energyWindow',.01,'eventThreshold',80,'spikesDetectionThreshold',-100);
names={'changePlotStyle','changeColorScale','changeTraceFilter','extraSpacing','plotEnergy','toogleDetectEvents','toogleDetectSpikes'};
called=0; callbacks=struct; for name=names, callbacks.(name{1})=@callback; end
[section,controls]=ce.ui.neuroscope.buildTraceSection(t.TestData.stack,settings,callbacks);
t.TestData.listener=ce.ui.layout.bindSection(section,t.TestData.stack,t.TestData.scroll); settle(t);
verifyEqual(t,controls.plotStyle.Value,2); verifyEqual(t,controls.extraSpacing.Value,1);
verifyEqual(t,controls.lowerBand.String,'400'); verifyEqual(t,controls.detectThreshold.String,'-100');
verifyEqual(t,numel(fieldnames(controls)),13);
controls.lowerBand.Callback(controls.lowerBand,[]); verifyEqual(t,called,1);
t.TestData.figure.Position(3)=230; settle(t); section.setCollapsed(true); settle(t);
section.setCollapsed(false); section.setFontSize(12); settle(t);
verifyEqual(t,called,1,'Layout must not invoke analysis callbacks.');
    function callback(~,~)
        called=called+1;
    end
end

function settle(t)
drawnow;
if isvalid(t.TestData.listener), t.TestData.listener.flush(); end
drawnow;
end
function testDeferredUpdateAndTimerCleanup(t)
s=t.TestData.section; before=t.TestData.scroll.MinimumHeights;
s.addField('late','Deferred field','edit'); pause(.1); drawnow;
verifyGreaterThan(t,t.TestData.scroll.MinimumHeights,before);
binding=t.TestData.listener; delete(s.Panel);
verifyFalse(t,isvalid(binding));
verifyEmpty(t,timerfindall('Name','CellExplorer section layout'));
end
