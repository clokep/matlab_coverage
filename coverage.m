% Look into profile on, profile -memory on, <run code>, profile off,
% stats = profile('info')
% inform = checkcode(filename, '-struct', '-id', '-codegen', '-cyc');

function coverage
%     clear classes;
    load sample;

    cov = FileCoverageSet(s);
    cov.report();
end
