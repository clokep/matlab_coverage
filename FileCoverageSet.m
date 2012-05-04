classdef FileCoverageSet < handle
    properties
        files = containers.Map();
    end
    
    methods
        function this = FileCoverageSet(info)
            % Accepts the output of profile('info');
            calls = info.FunctionTable;
            for it=1:length(calls)
                call = calls(it);
                
                % TODO Special handle empty FileName
                if (~this.files.isKey(call.FileName))
                    this.files(call.FileName) = FileCoverage(call);
                else
                    file = this.files(call.FileName);
                    file.add(call);
                    this.files(call.FileName) = file;
                end
            end
        end
        
        function report(this)
            keys = this.files.keys;
            for it=1:length(keys)
                file = this.files(keys{it});
                file.report();
            end
        end
    end
end
