classdef SentenceSplitter
    % SentenceSplitter this class is designed to split a single string into
    % a cell array of strings, representing a sequence of lines containing
    % wrapped text.
    
    properties(Access = private)
        JavaBreakIterator
    end
    
    methods (Access = public)
        function this = SentenceSplitter(locale)
            % SentenceSplitter can either be constructed with a Java locale
            % or alternatively left blank whereby a default will be
            % selected by the JVM
            switch nargin
                case 1
                    validateattributes(locale, {'java.util.Locale'}, {'scalar'})
                    this.JavaBreakIterator = java.text.BreakIterator.getLineInstance(locale);
                otherwise
                    this.JavaBreakIterator = java.text.BreakIterator.getLineInstance();
            end
        end
        
        function splitText = split(this, originalText, margin)
            % split   Split text into multiple lines
            %
            %   ss = curvefit.SentenceSplitter();
            %   ss.split( text, margin ) returns a cell array of strings which represent the
            %   text divided into sections which do not exceed the given margin
            
            validateattributes(margin, {'numeric'}, {'scalar'});
            this.JavaBreakIterator.setText(originalText);
            textLength = length(originalText);
            
            splitText = {};
            startOfThisLine = 1;
            numLines = 1;
            
            % 
            while (startOfThisLine < textLength - margin + 1);
                % The end of this line is the last possible break point preceeding the margin
                endOfThisLine = this.JavaBreakIterator.preceding(startOfThisLine+margin);
                
                % If the end of this line is before the start of this line it implies that there
                % are no split points before the margin. Thus the text must be divided at the
                % margin itself.
                if endOfThisLine <= startOfThisLine
                    endOfThisLine = startOfThisLine + margin - 1;
                end
                
                thisLine = originalText(startOfThisLine:endOfThisLine);
                thisLine = strtrim( thisLine );
                
                splitText{numLines} = thisLine; %#ok<AGROW>
                
                startOfThisLine = endOfThisLine + 1;
                numLines = numLines + 1;
            end
            
            finalLine = strtrim( originalText(startOfThisLine:end) );
            splitText{end+1} = finalLine;
        end
    end
end

