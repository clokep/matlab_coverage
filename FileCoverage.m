classdef FileCoverage < handle
    properties
        filename;
        functionNames = {};
        numLines = 0;
        executedLines = [];
        nonCodeLines = [];
        
        isJava = false;
        isMatlab = false;
        isMex = false;
    end
    
    methods
        function this = FileCoverage(info)
        % Accepts the output of profile('info') for an individual
        % FunctionTable.
        
            this.filename = info.FileName;
            
            switch (info.Type)
                case 'Java-method'
                    this.isJava = true;
                case 'M-script'
                    this.isMatlab = true;
                case 'M-anonymous-function'
                    this.isMatlab = true;
                case 'M-function'
                    this.isMatlab = true;
                case 'M-nested-function'
                    this.isMatlab = true;
                case 'M-subfunction'
                    this.isMatlab = true;
                case 'MEX-function'
                    this.isMex = true;
                otherwise
                    warning('Unknown type: %s.', info.Type);
            end
            
            if (this.isMatlab)
                this = this.countLines();
                this = this.checkForNonCodeLines();
                this.executedLines = false([this.numLines, 1]);
            end
            
            this = this.add(info);
        end
        
        function this = add(this, info)
        % Add another function call to the list.
            this.functionNames = [this.functionNames, {info.FunctionName}];
        
            if (this.isMatlab)
                this.executedLines(info.ExecutedLines(:, 1)) = true;
            end
        end
        
        function report(this)
            fprintf('%s: ', this.filename);
            coveredLines = this.coveredLines();
            if (~isempty(coveredLines))
                fprintf('%3.2f%%\n', mean(coveredLines) * 100);
                if (~all(coveredLines))
                    if (exist(this.filename, 'file'))
                        fprintf('===== Uncovered lines ======\n')
                        uncoveredLines = find(~coveredLines);
                        for jt=1:length(uncoveredLines)
                            dbtype(this.filename, num2str(uncoveredLines(jt)));
                            % Get rid of the extra lines that are added.
                            fprintf('\b\b');
                        end
                    else
                        fprintf('File is unavailable');
                    end
                end
            else
                fprintf('no coverage information available');
            end
            fprintf('\n');
        end
        
        function lines = coveredLines(this)
            if (~all(size(this.executedLines) == size(this.nonCodeLines)))
                % We'd expect this to happen if a file no longer exists on
                % the file system, so just use the info we have.
                lines = this.executedLines;
            else
                lines = this.executedLines | this.nonCodeLines;
            end
        end
    end
    
    methods (Access = protected)
        function this = countLines(this)
            fid = fopen(this.filename);
            this.numLines = 0;
            if (fid ~= -1)
                while (fgets(fid) ~= -1)
                    this.numLines = this.numLines + 1;
                end
                fclose(fid);
            end
        end
        
        function this = checkForNonCodeLines(this)
        % Returns a logical array where true is lines without code (empty
        % or comments).
        
            % Nothing to do here and avoid creating a 0x1 matrix.
            if (this.numLines == 0)
                return;
            end

            fid = fopen(this.filename);
            this.nonCodeLines = false([this.numLines, 1]);
            if (fid ~= -1)
                for it=1:this.numLines
                    fline = fgets(fid);
                    if (fline == -1)
                        return;
                    end
                    this.nonCodeLines(it) = ~isempty(regexp(fline, '^\s*(%.+)?$', 'ONCE')); % Allowed to be whitespace and / or a comment.
                    % This should handle block comments.
                end
                fclose(fid);
            end
        end
    end
end
