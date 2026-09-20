function R = skewness(i, FLAG, DIM)
% SKEWNESS estimates the skewness 
%
% y = skewness(x,DIM)
%   calculates skewness of x in dimension DIM
%
% FLAG (default=1): sample skewness
%     FLAG=1 returns the "method of moments estimator" [2]
% 	  g1 = mean((x-mu)).^3 ./ mean((x-mu).^2).^(3/2)
%     FLAG=-1 uses unbiased estimate of std - this was the default before
%         introducing the FLAG argument, and available for backwards compatibility.
%     FLAG=0 uses unbias estimated for std - this was the default before
%         introducing the FLAG argument, and available for backwards compatibility.
% 	   mean((x-mu)).^3 ./ std(x).^3
%
% DIM	dimension
%	1: STATS of columns
%	2: STATS of rows
%	default or []: first DIMENSION, with more than 1 element
%
% features:
% - can deal with NaN's (missing values)
% - dimension argument 
% - compatible to Matlab and Octave
%
% see also: SUMSKIPNAN, STATISTIC
%
% REFERENCE(S):
% [1] https://mathworld.wolfram.com/Skewness.html
% [2] https://en.wikipedia.org/wiki/Skewness
% [3] Joanes, D. N.; Gill, C. A. (1998).
%     Comparing measures of sample skewness and kurtosis.
%     Journal of the Royal Statistical Society, Series D. 47 (1): 183–189.
%     doi:10.1111/1467-9884.00122.
% [4] Doane, David P., and Lori E. Seward.
%     Measuring skewness: a forgotten statistic.
%     Journal of Statistics Education 19.2 (2011): 1-18. (Page 7)

%    Copyright (C) 2000-2003,2010,2022 by Alois Schloegl <alois.schloegl@gmail.com>
%    This function is part of the NaN-toolbox
%       http://pub.ist.ac.at/~schloegl/matlab/NaN/

%    This program is free software; you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation; either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program; If not, see <http://www.gnu.org/licenses/>.



% check input arguments 
if (nargin < 1)
	help skewness
	error('Invalid call')
end
if ~isnumeric(i)
	error('X must be a numeric vector or matrix')
end

if (nargin<2) || isempty(FLAG)
	FLAG = 1;
end
if ~isscalar(FLAG) || ~any(FLAG==[-1,0,1])
	error('FLAG must be 0 or 1')
end
if nargin<3,
        DIM = find(size(i)>1,1);
        if isempty(DIM), DIM=1; end;
end;
if (~isscalar (DIM) || DIM~=fix(DIM) || DIM <= 0)
	error ('size: DIM must be a positive integer');
end



[R.SUM,R.N,R.SSQ] = sumskipnan(i,DIM);	% sum

R.MEAN 	= R.SUM./R.N;			% mean 
R.SSQ0	= R.SSQ - real(R.SUM).*real(R.MEAN) - imag(R.SUM).*imag(R.MEAN); % sum square with mean removed

n1 	= max(R.N-1,0);			% in case of n=0 and n=1, the (unbiased) variance, STD and SEM are INF

R.VAR	= R.SSQ0./n1;	     		% variance
R.STD	= sqrt(R.VAR);		     	% standard deviation

i       = i - repmat(R.MEAN,size(i)./size(R.MEAN));
M3N 	= sumskipnan(i.^3,DIM);
M3 	= M3N./R.N;
M2 	= R.SSQ0./R.N;
%R.CM4 	= sumskipnan(i.^4,DIM)./n1;

if (FLAG==-1)
	%% traditional method, for backwards compatibility (NaN-toolbox 3.7.0 and earlier)
	R.CM3 	= M3N./n1;
	R = R.CM3./(R.STD.^3);
elseif (FLAG==0)
	%% sample skewness according to [3,4], which is G1 accoding to [2].
	R = sqrt(R.N.*n1).*M3./(max(R.N-2,0).*M2.^(3/2));
elseif (FLAG==1)
	%% method of moments, this is g1 according to [2].
	R = M3./(M2.^(3/2));
end

if isa(i,'single')
	R = single(R);
end


% The tests below have been copied from Octave's skewness function, thus 
%    Copyright (C) 1996-2022 The Octave Project Developers
% and adapted by A. Schlögl, 2022


%!assert (skewness ([-1, 0, 1]), 0)
%!assert (skewness ([-2, 0, 1]) < 0)
%!assert (skewness ([-1, 0, 2]) > 0)
%!assert (skewness ([-3, 0, 1]) == -1 * skewness ([-1, 0, 3]))
%!assert (skewness (ones (3, 5)), NaN (1, 5))
%!assert (skewness (1, [], 3), NaN)

%!test
%! x = [0; 0; 0; 1];
%! y = [x, 2*x];
%! assert (skewness (y), 1.154700538379251 * [1 1], 5*eps);

%!assert (skewness ([1:5 10; 1:5 10],  0, 2), 1.439590274527954 * [1; 1], eps)
%!assert (skewness ([1:5 10; 1:5 10],  1, 2), 1.051328089232020 * [1; 1], 2*eps)
%!assert (skewness ([1:5 10; 1:5 10], [], 2), 1.051328089232020 * [1; 1], 2*eps)

## Test behavior on single input
%!assert (skewness (single ([1:5 10])), single (1.0513283), eps ("single"))
%!assert (skewness (single ([1 2]), 0), single (NaN))

## Verify no warnings
%!test
%! lastwarn ("");  # clear last warning
%! skewness (1);
%! assert (lastwarn (), "");

## Test input validation
%!error <Invalid call> skewness ()
%!error <X must be a numeric vector or matrix> skewness (['A'; 'B'])
%!error <FLAG must be 0 or 1> skewness (1, 2)
%!error <FLAG must be 0 or 1> skewness (1, [1 0])
%!error <size: DIM must be a positive integer> skewness (1, [], ones (2,2))
%!error <DIM must be a positive integer> skewness (1, [], 1.5)
%!error <size: DIM must be a positive integer> skewness (1, [], 0)

