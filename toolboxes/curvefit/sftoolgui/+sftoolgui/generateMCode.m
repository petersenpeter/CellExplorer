function generateMCode( hSftool, filename )
%GENERATEMCODE   Generate code from an SFTOOL session.
%
%   GENERATEMCODE( SFTOOL ) writes code to the MATLAB Editor if it is available.
%   If it is not available, then the user is prompted to select a file to write
%   the generated code to.
%
%   GENERATEMCODE( SFTOOL, FILENAME ) writes code to file with the given
%   FILENAME.

%   Copyright 2008-2011 The MathWorks, Inc.

% We can only write to the editor if it is available.
editorIsAvailable = isempty( javachk( 'mwt', 'The MATLAB Editor' ) );

% But if we have been given the name of a file, we should write to that.
filenameGiven = nargin >= 2 && ~isempty( filename );

% We will write to the editor if it is available AND we have not been supplied
% with a file name
isWriteToEditor = editorIsAvailable && ~filenameGiven;

% Main options to write the code
options.OutputTopNode = false;
options.ReverseTraverse = false;
options.ShowStatusBar = true;

% Other options depend on the availability of the Editor
if isWriteToEditor
    options.Output = '-editor';
    options.MFileName = '';
else
    options.Output = '-string';
    if ~filenameGiven
        filename = iAskForFilename( hSftool );
        if isempty( filename )
            % User clicked cancel
            return
        end
    end
    % In the options, only store the name, not the path or the extension,
    % otherwise these get added to the code
    [~, options.MFileName] = fileparts( filename );
end

% Create the codeprogram object:
hProgram = codegen.codeprogram;
% Ask the SFTOOL object to make the code
hFunction = makeMCode( hSftool );
% Add the function as a subfunction of the program.
hProgram.addSubFunction( hFunction );
% Obtain a string representing the generated code:
codeString = hProgram.toMCode( options );

% Flatten the code to a char array.
str = sprintf( '%s\n', codeString{:} );

if isWriteToEditor
    % Output the result to the editor and smart-indent it:
    editorDoc = matlab.desktop.editor.newDocument(str);
    editorDoc.smartIndentContents;
else
    % Otherwise write code to file
    iWriteCodeToFile( str, filename );
end

end

function iWriteCodeToFile(mcode_str,filename)

fid = fopen( filename, 'w' );

if fid < 0
    emsg = getString(message('curvefit:sftoolgui:CouldNotCreateFile', filename ));
    errordlg( emsg, getString(message('curvefit:sftoolgui:ErrorGeneratingCode')), 'modal' );
else
    fprintf( fid, '%s', mcode_str );
    fclose( fid );
end
end

function filename = iAskForFilename( hSftool )
% iAskForFilename -- Ask the user to supply the name of file for us to write the
% code to.

% If the session has a name, then initialize the file picker to start in the
% same directory
path = fileparts( hSftool.SessionName );
if isempty( path );
    path = pwd;
end

filespec = fullfile( path, '*.m' );

[filename, path] = uiputfile( filespec, getString(message('curvefit:sftoolgui:GenerateCode')) );

% If either the filename or the path is zero, then the user clicked "cancel" and
% we should return early.
if isequal( filename, 0 ) || isequal( path, 0 )
    filename = '';
    return
end

% Ensure that there is an extension on the name
[~, ~, ext] = fileparts( filename );
if isempty( ext )
    filename = sprintf( '%s.m', filename );
end

% Reconstruct the full path for return
filename = fullfile( path, filename );

end
