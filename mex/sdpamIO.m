function [objVal,x0,X0,Y0,INFO] = sdpamIO(mDIM,nBLOCK,bLOCKsTRUCT,A,b,c,K,~,OPTIONS)
% SDPAMIO  Call the SDPA solver without MEX interface using file I/O.
%
%   [objVal,x0,X0,Y0,INFO] = SDPAMIO(mDIM,nBLOCK,bLOCKsTRUCT,A,b,c,K,~,OPTIONS)
%
%   See also sdpam.

% Copyright 2016-2018 Kai T. Ohlhus (kai.ohlhus@tuhh.de)

input_file  = [tempname(), '.dat-s'];
result_file = [tempname(), '.result'];
option_file = [tempname(), '.result'];
% gensdpafile (input_file, mDIM, nBLOCK, bLOCKsTRUCT, ct, F);  % Too slow
writesdpa (input_file, A, b, c, K);  % From CSDP
% 'writesdpa' puts the linear cones to the back.
idx = (bLOCKsTRUCT < 0);  % Indices of linear cones.
bLOCKsTRUCT = [bLOCKsTRUCT(~idx), bLOCKsTRUCT(idx)];
create_sdpam_options_file (option_file, OPTIONS);
redirect_str = '';
if (isstruct (OPTIONS) && isfield (OPTIONS, 'print'))
  if (strcmpi (OPTIONS.print, 'no'))
    redirect_str = '>/dev/null';
  elseif (~strcmpi (OPTIONS.print, 'display'))
    redirect_str = ['>', OPTIONS.print];
  end
end
% call csdp solver
system (sprintf ('sdpa -ds %s -o %s -p %s %s', input_file, result_file, ...
  option_file, redirect_str));
[x0,X0,Y0] = read_sdpam_result (result_file, mDIM, nBLOCK, bLOCKsTRUCT);
delete (input_file);
delete (result_file);
delete (option_file);
% Revert order of 'writesdpa'.
idx = (bLOCKsTRUCT < 0);  % Indices of linear cones.
X0 = [X0(idx(:)); X0(~idx(:))];
Y0 = [Y0(idx(:)); Y0(~idx(:))];
% If everythink went well up to here, return success.
objVal = [];
INFO.phasevalue = 'pdOPT';
end



function create_sdpam_options_file (filename, opts)
% CREATE_SDPAM_OPTIONS_FILE  Writes a file with SDPA options to filename.
%
%   CREATE_SDPAM_OPTIONS_FILE(filename, opts) filename is the name of the file
%      and opts is a structure created with SDPA's 'param' command.

opts = param(opts);
f = fopen(filename, 'w');
if (isfield(opts,'maxIteration'))
  fprintf(f, '%d\tunsigned int maxIteration;\n', opts.maxIteration);
end
if (isfield(opts,'epsilonStar'))
  fprintf(f, '%.1E\tdouble 0.0 < epsilonStar;\n', opts.epsilonStar);
end
if (isfield(opts,'lambdaStar'))
  fprintf(f, '%.1E\tdouble 0.0 < lambdaStar;\n', opts.lambdaStar);
end
if (isfield(opts,'omegaStar'))
  fprintf(f, '%.1f\tdouble 1.0 < omegaStar;\n', opts.omegaStar);
end
if (isfield(opts,'lowerBound'))
  fprintf(f, '%.1E\tdouble lowerBound;\n', opts.lowerBound);
end
if (isfield(opts,'upperBound'))
  fprintf(f, '%.1E\tdouble upperBound;\n', opts.upperBound);
end
if (isfield(opts,'betaStar'))
  fprintf(f, '%.1f\tdouble 0.0 <= betaStar <  1.0;\n', opts.betaStar);
end
if (isfield(opts,'betaBar'))
  fprintf(f, '%.1f\tdouble 0.0 <= betaBar  <  1.0, betaStar <= betaBar;\n', ...
    opts.betaBar);
end
if (isfield(opts,'gammaStar'))
  fprintf(f, '%.1f\tdouble 0.0 < gammaStar  <  1.0;\n', opts.gammaStar);
end
if (isfield(opts,'epsilonDash'))
  fprintf(f, '%.1E\tdouble 0.0 < epsilonDash;\n', opts.epsilonDash);
end
if (isfield(opts,'xPrint'))
  fprintf(f, ...
    '%s     char*  xPrint   (default %+8.3e,   NOPRINT skips printout)\n', ...
    opts.xPrint);
end
if (isfield(opts,'XPrint'))
  fprintf(f, ...
    '%s     char*  XPrint   (default %+8.3e,   NOPRINT skips printout)\n', ...
    opts.XPrint);
end
if (isfield(opts,'YPrint'))
  fprintf(f, ...
    '%s     char*  YPrint   (default %+8.3e,   NOPRINT skips printout)\n', ...
    opts.YPrint);
end
if (isfield(opts,'infPrint'))
  fprintf(f, ...
    '%s     char*  infPrint (default %+10.16e, NOPRINT skips printout)\n', ...
    opts.infPrint);
end
fclose(f);
end


function [x0,X0,Y0] = read_sdpam_result (filename, mDIM, nBLOCK, bLOCKsTRUCT)
% READ_SDPAM_RESULT  Reads a computed result file from the SDPA solver
%
%   [x0,X0,Y0] = READ_SDPAM_RESULT(filename,mDIM,nBLOCK,bLOCKsTRUCT)
%
%   The format is explained in Section 8 in the file:
%   https://sourceforge.net/projects/sdpa/files/sdpa-m/sdpamManual.pdf

str = fileread (filename);
xVecIdx = strfind (str, 'xVec');
xMatIdx = strfind (str, 'xMat');
yMatIdx = strfind (str, 'yMat');
endIdx  = strfind (str, 'main loop time');

xVecStr = str(xVecIdx(end):xMatIdx(end));
idx1 = strfind (xVecStr, '{');
idx2 = strfind (xVecStr, '}');
xVecStr = xVecStr((idx1(1) + 1):(idx2(end) - 1));
x0 = read_vector_from_string(xVecStr,mDIM);

xMatStr = str(xMatIdx(end):yMatIdx(end));
yMatStr = str(yMatIdx(end):endIdx(end));
X0 = read_cell_matrix_from_string (xMatStr, nBLOCK, bLOCKsTRUCT);
Y0 = read_cell_matrix_from_string (yMatStr, nBLOCK, bLOCKsTRUCT);
end


function C = read_cell_matrix_from_string (str, nBLOCK, bLOCKsTRUCT)
C = cell(nBLOCK,1);
idx1 = strfind (str, '{');
idx2 = strfind (str, '}');
str = str(idx1(1) + 1: idx2(end) - 1);
for i = 1:nBLOCK
  idx1 = strfind (str, '{');
  idx1 = idx1(1) + 1;
  idx2 = idx1 + 1;
  j = 1;
  while (j ~= 0)
    switch(str(idx2))
      case '{'
        j = j + 1;
      case '}'
        j = j - 1;
    end
    idx2 = idx2 + 1;
  end
  if (bLOCKsTRUCT(i) > 0)
    C{i} = read_matrix_from_string(str(idx1:idx2 - 2),bLOCKsTRUCT(i));
  else
    C{i} = read_vector_from_string(str(idx1:idx2 - 2),-bLOCKsTRUCT(i));
  end
  str = str(idx2:end);
end
assert(length(C) == nBLOCK)
end


function C = read_matrix_from_string (str, dim)
C = zeros(dim);
idx1 = strfind (str, '{');
idx2 = strfind (str, '}');
assert (length(idx1) == dim)
assert (length(idx1) == length(idx2))
for i = 1:dim
  C(i,:) = read_vector_from_string (str((idx1(i) + 1):(idx2(i) - 1)), dim);
end
end

function c = read_vector_from_string (str, len)
c = sscanf (str, '%f,');
assert (length (c) == len);
end
