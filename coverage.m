% Look into profile on, profile -memory on, <run code>, profile off,
% stats = profile('info')

function coverage
    load sample
    
    files = containers.Map();

    calls = s.FunctionTable;
    for it=1:length(calls)
        fnc = calls(it);

        if (~files.isKey(fnc.FileName))
            nLines = countLines(fnc.FileName);
            files(fnc.FileName) = checkForNonCodeLines(fnc.FileName, nLines);
        end
        executedLines = files(fnc.FileName);
        executedLines(fnc.ExecutedLines(:, 1)) = true;
        files(fnc.FileName) = executedLines;
    end

    keys = files.keys;
    for it=1:length(keys)
        executedLines = files(keys{it});
        fprintf('%s: ', keys{it});
        if (~isempty(executedLines))
            fprintf('%f\n', mean(executedLines));
            if (~all(executedLines))
                fprintf('===== Uncovered lines ======\n')
                uncoveredLines = find(~executedLines);
                for jt=1:length(uncoveredLines)
                    dbtype(keys{it}, num2str(uncoveredLines(jt)));
                    fprintf('\b\b'); % Get rid of the extra lines added.
                end
            end
        else
            fprintf('no coverage information available');
        end
        fprintf('\n');
    end
    
    % Also look into :
    inform = checkcode(filename, '-struct', '-id', '-codegen', '-cyc');
end

function nLines = countLines(filename)
    fid = fopen(filename);
    nLines = 0;
    if (fid ~= -1)
        while (fgets(fid) ~= -1)
            nLines = nLines + 1;
        end
        fclose(fid);
    end
end

function isNotCode = checkForNonCodeLines(filename, nLines)
% Returns a logical array where true is lines without code (empty or
% comments).

    fid = fopen(filename);
    isNotCode = false([nLines, 1]);
    if (fid ~= -1)
        for it=1:nLines
            fline = fgets(fid);
            if (fline == -1)
                return;
            end
            isNotCode(it) = ~isempty(regexp(fline, '^\s*(%.+)?$', 'ONCE')); % Allowed to be whitespace and / or a comment.
            % This should handle block comments.
        end
        fclose(fid);
    end
end
