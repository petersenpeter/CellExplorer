classdef FittypeGenerator < curvefit.Handle & sftoolgui.fittypespec.FittypeSpecificationVisitor
    % FittypeGenerator   Generate code from fittype specifications.

    %   Copyright 2013 The MathWorks, Inc.

    properties(Access = private)
        % Code   (sftoolgui.codegen.MCode) The code object to add generated code to
        Code
    end
    
    methods
        function this = FittypeGenerator( code )
            % FittypeGenerator   Constructor for sftoolgui.codegen.FittypeGenerator
            %
            % Syntax:
            %   code = sftoolgui.codegen.MCode();
            %   g = sftoolgui.codegen.FittypeGenerator( code )
            this.Code = code;
        end
        
        % Curves
        function visitCustomNonLinearCurveSpecification( this, specification )
            % visitCustomNonLinearCurveSpecification   Generate code for a custom non-linear
            % curve
            this.addCodeForStandardHeader();
            
            ft = specification.Fittype;
            
            aFormula = sftoolgui.codegen.stringLiteral( formula( ft ) );
            
            this.Code.addFunctionCall( '<ft>', '=', 'fittype', ...
                iStringToCodeString( aFormula ), ...
                '''independent''', iNameOfIndependentForCurve( ft ), ...
                '''dependent''', iNameOfDependentVariable(ft) );
        end
        
        function visitLibrarySpecification( this, specification )
            % visitLibrarySpecification   Generate code for a curve library model
            generateCodeForLibraryModel( this, specification );
        end
        
        function visitSmoothingSplineCurveSpecification( this, specification )
            % visitSmoothingSplineCurveSpecification   Generate code for a smoothing spline
            generateCodeForLibraryModel( this, specification );
        end
        
        function visitCustomLinearCurveSpecification( this, specification )
            % visitCustomLinearCurveSpecification   Generate code for a custom linear curve
            this.addCodeForStandardHeader();
            
            ft = specification.Fittype;
            
            this.Code.addFunctionCall( '<ft>', '=', 'fittype', ...
                iLinearTerms( ft ), ...
                '''independent''', iNameOfIndependentForCurve( ft ), ...
                '''dependent''', iNameOfDependentVariable( ft ), ...
                '''coefficients''', iNamesOfCoefficients( ft ) );
        end
        
        function visitInterpolantCurveSpecification( this, specification )
            % visitInterpolantCurveSpecification   Generate code for a curve interpolant
            generateCodeForInterpolant( this, specification );
        end
        
        % Surfaces
        function visitPolynomialSurfaceSpecification( this, specification )
            % visitPolynomialSurfaceSpecification   Generate code for a polynomial surface
            generateCodeForLibraryModel( this, specification );
        end
        
        function visitLowessSurfaceSpecification( this, specification )
            % visitLowessSurfaceSpecification   Generate code for a lowess surface
            generateCodeForLibraryModel( this, specification );
        end
        
        function visitCustomNonLinearSurfaceSpecification( this, specification )
            % visitCustomNonLinearSurfaceSpecification   Generate code for a custom
            % non-linear surface
            this.addCodeForStandardHeader();
            
            ft = specification.Fittype;
            
            aFormula = sftoolgui.codegen.stringLiteral( formula( ft ) );
            
            this.Code.addFunctionCall( '<ft>', '=', 'fittype', ...
                sprintf( '''%s''', aFormula ), ...
                '''independent''', iNameOfIndependentForSurface(ft), ...
                '''dependent''', iNameOfDependentVariable(ft) );
        end
        
        function visitInterpolantSurfaceSpecification( this, specification )
            % visitCustomNonLinearSurfaceSpecification   Generate code for a surface
            % interpolant
            generateCodeForInterpolant( this, specification );
        end
    end
    
    methods(Access = private)
        function addCodeForStandardHeader( this )
            % addCodeForStandardHeader   Add the "standard header" code for a fittype.
            %
            % The "standard header" code includes a comment that the code is for the fittype
            % and includes a variable to store the fittype in.
            mcode = this.Code;
            addVariable( mcode, '<ft>', 'ft' );
            
            % Add a blank line to separate sections of code
            addBlankLine( mcode );
            % Add a comment for the fittype section
            addFitComment( mcode, getString(message('curvefit:sftoolgui:SetUpFittypeAndOptions')) );
        end
        
        function generateCodeForLibraryModel( this, specification )
            % generateCodeForLibraryModel   Generate code for a library model
            this.addCodeForStandardHeader();

            typeString = iStringToCodeString( type( specification.Fittype ) );
            this.Code.addFunctionCall( '<ft>', '=', 'fittype', typeString );
        end
        
        function generateCodeForInterpolant( this, specification )
            % generateCodeForInterpolant   Generate code for an interpolant
            this.addCodeForStandardHeader();
            
            typeString = iStringToCodeString( type( specification.Fittype ) );
            this.Code.addAssignment( '<ft>', typeString );
        end
    end
end

function independentName = iNameOfIndependentForCurve(ft)
% iNameOfIndependentForCurve
independentVariables = indepnames( ft );
independentName = iStringToCodeString( independentVariables{1} );
end

function independentNames = iNameOfIndependentForSurface(ft)
% iNameOfIndependentForSurface
independentNames = iCellStringToCodeString( indepnames( ft ) );
end

function dependentName = iNameOfDependentVariable(ft)
% iNameOfDependentVariable
dependentVariables = dependnames( ft );
dependentName = iStringToCodeString( dependentVariables{1} );
end

function coefficientNames = iNamesOfCoefficients(ft)
% iNamesOfCoefficients
coefficientNames = iCellStringToCodeString( coeffnames( ft ) );
end

function terms = iLinearTerms(ft)
% iLinearTerms
linearTerms = linearterms( ft );
terms = iCellStringToCodeString( linearTerms );
end

function string = iCellStringToCodeString( cellString )
% iCellStringToCodeString   Convert a cell array of strings into the single
% string that evaluates to the original cell array of strings.
prefix = '{''';
delimiter = ''', ''';
suffix = '''}';
literalCellString = sftoolgui.codegen.stringLiteral( cellString );
string = [prefix, strjoin( literalCellString(:).', delimiter ), suffix];
end

function codeString = iStringToCodeString( string )
% iStringToCodeString   Convert a string (char row vector) into string that
% evaluates to the original string.
codeString = sprintf( '''%s''', string );
end

