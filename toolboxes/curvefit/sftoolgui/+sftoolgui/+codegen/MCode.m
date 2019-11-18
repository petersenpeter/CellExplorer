classdef MCode < curvefit.Handle
    % MCode   The MCode object represents code generated from a CFTOOL session
    %
    %
    %   The code can include various tokens. In the generated code,
    %   these tokens will be replaced by appropriate variables name. The
    %   allowed tokens and their meanings are:
    %
    %       <fo>    fit object
    %       <gof>   goodness-of-fit
    %       <x-name> name of the x variable
    %       <y-name> name of the y variable
    %       <z-name> name of the z variable
    %       <w>     weights
    %
    %   This token can be used in various "add" methods, e.g.,
    %
    %       h = sftoolgui.codegen.MCode();
    %       h.startNewFit();
    %       h.addFunctionCall( '<fo>', '=', 'fit', '<x-name>', '<y-name>, '<ft>' );
    %
    %   In the generated code, each of these variables may vary with each fit.
    
    %   Copyright 2008-2013 The MathWorks, Inc.

    properties(Access = 'private', Constant = true)
        % FitVariableTokens -- Tokens that can be used in code but that will be
        % replaced by the corresponding variable for the fit.
        FitVariableTokens = {'<x-name>', '<y-name>', '<z-name>', '<w-name>', '<xv-name>', '<yv-name>', '<zv-name>'};
    end
    properties(SetAccess = 'private', GetAccess = 'private')
        % FitResult -- variable name for the fit object(s) that get returned by the
        % generated code
        FitResult = 'fitresult';
        
        % GOFVariable -- variable name for the goodness-of-fit (GOF) structure
        % that gets returned by the generated code
        GOFVariable = 'gof';
        
        % Inputs -- List of inputs to the generated code
        Inputs = {};
        
        % FitVariables -- Indices into Inputs for the of the variables for each fit
        FitVariables;
        
        % HelpComments -- Text of the comment "help" block of the code
        HelpComments = '';
        
        % FitBlocks -- Cell-array of cell-strings.
        %
        %   FitBlocks{n} is a cell-array of strings and represents the code that
        %   fits and plots the n-th fit in the session.
        FitBlocks = {}
        
        % VariableTokens -- Cell-array of strings
        VariableTokens = {}
        % Variables -- Cell-array of strings
        Variables = {}
        
        % FunctionNames -- Cell-array of strings
        %
        %   List of all functions the generated code will call.
        FunctionNames = {};
    end
    
    methods
        function h = MCode
            h.FitVariables = zeros( 0, length( h.FitVariableTokens ) );
            
            % Declare all the variables that will be used for fitting
            addVariable( h, '<x-input>', 'xData' );
            addVariable( h, '<y-input>', 'yData' );
            addVariable( h, '<z-output>', 'zData' );
            addVariable( h, '<weights>', 'weights' );
            % ... and validation
            addVariable( h, '<validation-x>', 'xValidation' );
            addVariable( h, '<validation-y>', 'yValidation' );
            addVariable( h, '<validation-z>', 'zValidation' );
        end
        
        function startNewFit( h )
            % startNewFit   Notify MCode object of start of new fit
            h.FitBlocks{end+1} = {};
            h.FitVariables(end+1,:) = 0;
        end
        
        function setFitVariable( h, variable, name )
            % setFitVariable   Set a variable for this fit
            %
            %   setFitVariable( h, '<x-name>', name )
            %   setFitVariable( h, '<y-name>', name )
            %   setFitVariable( h, '<z-name>', name )
            %   setFitVariable( h, '<weights>', name )
            [tf, tokenLocation] = ismember( variable,  h.FitVariableTokens );
            if tf
                addInput( h, name );
                [~, inputLocation] = ismember( name, h.Inputs );
                h.FitVariables(end,tokenLocation) = inputLocation;
            else
                error(message('curvefit:sftoolgui:MCode:InvalidFitVariable'));
            end
        end
        
        function addVariable( h, token, name )
            % addVariable   Register a variable to the generated code
            %
            % Syntax:
            %   h.addVariable( token, name )
            if ismember( token, h.VariableTokens )
                % do nothing
            else
                h.VariableTokens{end+1} = token;
                h.Variables{end+1}      = name;
            end
        end
        
        function addHelpComment( h, comment )
            % addHelpComment   Register a line in the help comments
            %
            %   See also: addFitComment
            h.HelpComments = sprintf( '%s\n%s', h.HelpComments, comment );
        end
        
        function addFitComment( h, comment )
            % addFitComment  Add a comment line to the code for fitting a surface
            %
            %   addFitComment( H, COMMENT ) adds the comment, COMMENT, to the
            %   MATLAB Code to be generated, H. COMMENT should be a char array
            %   representing a single line, i.e., it should not a '\n' in it.
            %
            %   A comment character followed by a space, '% ', is prepended to
            %   the comment before it is written to the file.
            %
            %   The COMMENT should be translated before passing into this
            %   method, e.g.,
            %       addFitComment( mcode, getString( message( 'some:example:id' ) ) )
            %
            %   See also: addHelpComment
            h.FitBlocks{end}{end+1} = iMakeComment( comment );
        end
        
        function addCellHeader( h, line )
            % addCellHeader  Add a cell header to the code for fitting a surface 
            %
            %   addCellHeader( H, COMMENT ) adds the line, LINE, to the MATLAB
            %   Code to be generated, H, and makes it into a cell header. LINE
            %   should be a char array representing a single line, i.e., it
            %   should not a '\n' in it.
            %
            %   The cell-header markup followed by a space, '%% ', is prepended
            %   to the line before it is written to the file.
            h.FitBlocks{end}{end+1} = iMakeCellHeader( line );
        end
        
        function addBlankLine( h )
            % addBlankLine  Add a blank line into code
            %
            %  addBlankLine( H ) adds an empty line in the MATLAB code to be 
            %  generated, H.
            h.FitBlocks{end}{end+1} = '';
        end
        
        function addFunctionCall( h, varargin )
            % addFunctionCall   Add a function call to generated code.
            %
            % To add a call to the function f, i.e., to generate code like "f();"
            %     h.addFunctionCall( 'f' );
            %
            % To specify input arguments, pass extra arguments after the function name, e.g.,
            %     h.addFunctionCall( 'f', 'x' ) --> "f( x );"
            %     h.addFunctionCall( 'f', 'a', '''a string''' ) --> "f( a, 'a string' );"
            %
            % To specify output arguments, use the string equals, '=', as one input. Anything
            % before the equal is an output. The string after is the function name and
            % anything use is inputs, e.g.,
            %     h.addFunctionCall( 'y', '=', 'f', 'x' ) --> "y = f(x);"
            %     h.addFunctionCall( 'y', '=', 'f', 'a', 'b' ) --> "y = f( a, b );"
            %     h.addFunctionCall( 'x', 'y', '=', 'f', 'a', 'b' ) --> "[x, y] = f( a, b );"
            %
            % Tokens can be used for variable names, e.g.,
            %     h.addFunctionCall( '<fo>, '<gof>', '=' 'fit', '<x-name>', '<y-name>', '''poly1''' ) 
                        
            % Find the equals sign in the input arguments
            equalsIndex = iFindEqualsSign( varargin{:} );
	
            % Anything before the equals sign is an output
            outputs = varargin(1:equalsIndex-1);
            % The argument just after the equals sign is the function name
            functionName = varargin{equalsIndex+1};
            % Everything after the function name is an input argument.
            inputs = varargin(equalsIndex+2:end);

            % Generate a string that represents the MATLAB code for a function call
            inputList = iJoin( inputs );
            outputList = iLeftHandSide( outputs );
            code = sprintf( '%s%s( %s );', outputList, functionName, inputList );
            % Add the code to the block for the current fit
            h.addFitCode( code );
            
            % Record this function as one that is used in the generated code
            h.FunctionNames{end+1} = functionName;
        end
        
        function addCommandCall( h, functionName, argument )
            % addCommandCall   Add a command call to generated code.
            %
            % This is the "command dual" form of addFunctionCall.
            %
            % Syntax:
            %    h.addCommandCall( functionName, argument )
            %
            %    For the command-dual, all arguments are strings.
            %
            % Example
            %   h.addCommandCall( 'hold', 'on' );
            %
            % See also: addFunctionCall.
            code = sprintf( '%s %s', functionName, argument );
            
            % Add the code to the block for the current fit
            h.addFitCode( code );
            
            % Record this function as one that is used in the generated code
            h.FunctionNames{end+1} = functionName;
        end
        
        function addMessyFunctionCall( h, code, functionNames )
            % addMessyFunctionCall   Add a "messy" function call to the generated code.
            %
            % Syntax:
            %   h.addMessyFunctionCall( code, functionNames )
            %
            % Inputs
            %   code -- a char array that is code to be inserted in the generated code
            %   functionNames -- cell-string (row) of names of functions in the code to be
            %      added
            %
            % To add a nested function call:
            %   h.addMessyFunctionCall( '<nNaN> = nnz( isnan( <residual> ) );', {'nnz', 'isnan'} );
            %
            % To add a function call into a indexing operation
            %   h.addMessyFunctionCall( '<residual>(isnan( <residual> )) = [];', {'isnan'} );
            %
            % To concatenate the results of multiple function calls
            %   h.addMessyFunctionCall( '<xlim> = [min( [<x-input>; <validation-x>] ), max( [<x-input>; <validation-x>] )];', {'min', 'max'} );
            %
            % To apply a math operation to the return from a function
            %   h.addMessyFunctionCall( '<sse> = norm( <residual> )^2;', {'norm'} ); 
            h.addFitCode( code );
            h.FunctionNames = [h.FunctionNames, functionNames];
        end
        
        function addAssignment( h, lhs, rhs )
            % addAssignment   Adds an assignment to generated code
            %
            % Syntax:
            %   h.addAssignment( lhs, rhs )
            %
            % Example: To add the assignment x = a + b to generated code, use
            %   h.addFitCode( 'x', 'a + b' );
            h.addFitCode( [lhs, ' = ', rhs, ';'] );
        end
        
        function hFunction = writeTo( h, hFunction )
            % writeTo   Write an MCode object to a codegen.coderoutine object
            nFits = length( h.FitBlocks );
            
            % Set the names of the output and temporary variables
            finalizeVariables( h );

            % Add header information
            % -- name the function.
            if nFits == 1
                hFunction.Name = 'createFit';
            else
                hFunction.Name = 'createFits';
            end
            % -- register input arguments
            h.addArgumentsIn( hFunction );
            % -- register output arguments
            hFunction.addArgout( h.FitResult );
            hFunction.addArgout( h.GOFVariable );
            % -- add help comments at top of file
            hFunction.Comment = generateHelpComment( h );
            hFunction.SeeAlsoList = {'fit', 'cfit', 'sfit'};

            % Add code to initialize output arguments
            if nFits > 1
            hFunction.addText( iMakeCellHeader( getString(message('curvefit:sftoolgui:Initialization')) ) );
            hFunction.addText( '' ); % blank line
                hFunction.addText( iMakeComment( getString(message('curvefit:sftoolgui:InitializeArraysToStoreFitsAndGoodnessOfFit')) ) );
                hFunction.addText( sprintf( '%s = cell( %d, 1 );', h.FitResult, nFits ) );
                hFunction.addText( sprintf( '%s = struct( ''sse'', cell( %d, 1 ), ...', h.GOFVariable, nFits ) );
                hFunction.addText( '''rsquare'', [], ''dfe'', [], ''adjrsquare'', [], ''rmse'', [] );' );
            end
            
            % Add code for fitting and plotting
            % -- get names of output variables as they change for each fit
            if nFits == 1
                fitObjectName = @(i) h.FitResult;
                gofName       = @(i) h.GOFVariable;
            else
                fitObjectName = @(i) sprintf( '%s{%d}', h.FitResult, i );
                gofName       = @(i) sprintf( '%s(%d)', h.GOFVariable, i );
            end
            % -- add fitting and plotting code for each fit in turn
            for i = 1:nFits
                hFunction.addText( '' );
                for j = 1:length( h.FitBlocks{i} )
                    thisLine = h.FitBlocks{i}{j};
                    thisLine = strrep( thisLine, '<fo>', fitObjectName( i ) );
                    thisLine = strrep( thisLine, '<gof>', gofName( i ) );
                    thisLine = replaceTokens( h, thisLine, i );
                    hFunction.addText( thisLine );
                end
            end
            hFunction.addText( '' );
        end
    end
    
    methods(Access = 'private' )
        function finalizeVariables( h )
            % finalizeVariables
            %
            % This method ensures that the variable names do not clash with any
            % of the inputs or any other variables that have been registered
            allNames = h.FunctionNames;
            
            % Variable names should not clash with function names
            h.Inputs = iGenerateVariableNames( h.Inputs, allNames );
            allNames = [allNames, h.Inputs];
            
            % FitResult
            h.FitResult = iGenerateVariableNames( h.FitResult, allNames );
            allNames{end+1} = h.FitResult;
            
            % Goodness of fit
            h.GOFVariable = iGenerateVariableNames( h.GOFVariable, allNames );
            allNames{end+1} = h.GOFVariable;
            
            % Temporary Variables
            h.Variables = iGenerateVariableNames( h.Variables, allNames );
        end
        
        function line = replaceTokens( h, line, fitIndex )
            % Replace tokens in a line of code
            for i = 1:length( h.FitVariableTokens )
                index = h.FitVariables(fitIndex,i);
                if index > 0
                    thisInput = h.Inputs{index};
                    line = strrep( line, h.FitVariableTokens{i}, thisInput );
                end
            end
            for i = 1:length( h.Variables )
                line = strrep( line, h.VariableTokens{i}, h.Variables{i} );
            end
        end
        
        function comments = generateHelpComment( h )
            % generateHelpComment   Generate the help comment that gets
            % inserted at the top of file.
            nFits = length( h.FitBlocks );
            if nFits == 1
                line1 = getString(message('curvefit:sftoolgui:CreateFit'));
                output1 = getString(message('curvefit:sftoolgui:Output')); 
                output2 = sprintf('    %s', getString(message('curvefit:sftoolgui:FitObjectRepresentingTheFit', h.FitResult )));
                output3 = sprintf('    %s', getString(message('curvefit:sftoolgui:StructureWithGoodnessOfFitInfo', h.GOFVariable )));
            else
                line1 = getString(message('curvefit:sftoolgui:CreateFits'));
                output1 = getString(message('curvefit:sftoolgui:Output'));
                output2 = sprintf('    %s', getString(message('curvefit:sftoolgui:CellarrayOfFitObjectsRepresentingTheFits', h.FitResult )));
                output3 = sprintf('    %s', getString(message('curvefit:sftoolgui:StructureArrayWithGoodnessOfFitInfo', h.GOFVariable )));
            end
            comments = sprintf( '%s\n%s\n%s\n%s\n%s', line1, h.HelpComments, output1, output2, output3 );
        end
        
        function addInput( h, input )
            % addInput   Register an input to the generated code
            if ismember( input, h.Inputs )
                % do nothing
            else
                h.Inputs{end+1} = input;
            end
        end
        
        function addArgumentsIn( h, hFunction )
            % addArgumentsIn   Add names of input arguments to a codegen.coderoutine
            for i = 1:length( h.Inputs )
                hFunction.addArgin( h.Inputs{i} );
            end
        end
        
        function addFitCode( h, code )
            % addFitCode   Add a code for fitting a surface to MCode object
            %
            %   addFitCode( H, CODE ) adds the code, CODE, to the MATLAB Code to
            %   be generated H. CODE should be a char array representing one of
            %   more lines. Separate multiple lines with a new line character,
            %   i.e., sprintf( '\n' ).
            h.FitBlocks{end}{end+1} = code;
        end
    end
end

function comment = iMakeComment( text )
% iMakeComment -- Make a comment from a piece of text
%
% The comment character plus a space, '% ' will be added to the TEXT to make the
% comment
comment = sprintf( '%% %s', text );
end

function cellHeader = iMakeCellHeader( text )
% iMakeComment -- Make a cell header from a piece of text
%
% The cell break symbol plus a space, '%% ' will be added to the TEXT to make
% the cell header.
cellHeader = sprintf( '%%%% %s', text );
end

function str = iJoin( cellstr )
% iJoin   Join elements of a cell-string into a comma-separated list
str = sprintf( '%s, ', cellstr{:} );
str(end-1:end) = '';
end

function code = iLeftHandSide( outputs )
% iLeftHandSide   A string that is the correct left hand side (including equals)
% for a given cell-string of output names.
switch length( outputs )
    case 0
        code = '';
    case 1
        code = sprintf( '%s = ', outputs{1} );
    otherwise % many outputs
        code = sprintf( '[%s] = ', iJoin( outputs ) );
end
end

function index = iFindEqualsSign( varargin )
% iFindEqualsSign   The index of the an equals sign, '=', in a cell-array of
% strings.
%
% If the an equal sign is not present, then index = 0 is returned.
[tf, index] = ismember( '=', varargin );
if ~any( tf )
    index = 0;
end
end

function names = iGenerateVariableNames( names, allNames )
names = matlab.lang.makeValidName( names );
names = matlab.lang.makeUniqueStrings( names, allNames, namelengthmax );
end
