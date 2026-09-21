function R = kurtosis(i, FLAG, DIM)
% KURTOSIS estimates the kurtosis
%
% y = kurtosis(x, FLAG, DIM)
%   calculates kurtosis of x in dimension DIM
%
% FLAG (default=1):
%     FLAG=1 returns the "method of moments estimator" [2]
% 	  k2 = mean((x-mu)).^4 ./ mean((x-mu).^2).^2 = g2+3 = m4/m2^2
%     FLAG=0 uses the "Standard unbiased estimator" (according to [2,3]) and returns
%         [(n+1)*g2+6]*(n-1)/((n-2)*(n-3)) + 3
%     FLAG=-1 uses unbiased estimate of std - this was the default before
%         introducing the FLAG argument, and available for backwards compatibility.
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
% see also: SUMSKIPNAN, VAR, STD, VAR, SKEWNESS, MOMENT, STATISTIC, 
%    IMPLICIT_SKIP_NAN
%
% REFERENCE(S):
% [1] https://mathworld.wolfram.com/Kurtosis.html
% [2] https://en.wikipedia.org/wiki/Kurtosis
% [3] Joanes, Derrick N.; Gill, Christine A. (1998),
%     "Comparing measures of sample skewness and kurtosis",
%     Journal of the Royal Statistical Society, Series D, 47 (1): 183–189,
%     doi:10.1111/1467-9884.00122, JSTOR 2988433

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

%	Copyright (C) 2000-2003,2022 by Alois Schloegl <alois.schloegl@gmail.com>
%       This function is part of the NaN-toolbox for Octave and Matlab 
%       http://pub.ist.ac.at/~schloegl/matlab/NaN/


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
R.SSQ0	= R.SSQ - real(R.SUM).*real(R.MEAN) - imag(R.SUM).*imag(R.MEAN);	% sum square with mean removed

n1 	= max(R.N-1,0);			% in case of n=0 and n=1, the (unbiased) variance, STD and SEM are INF

R.VAR  	= R.SSQ0./n1;	     		% variance
%R.STD	= sqrt(R.VAR);		     	% standard deviation

i       = i - repmat(R.MEAN,size(i)./size(R.MEAN));
%R.CM3 	= sumskipnan(i.^3,DIM)./n1;
M4N 	= sumskipnan(i.^4,DIM);
M4 	= M4N./R.N;
M2	= R.SSQ0./R.N;

k2      = M4./(M2.*M2)  %  [2], k2=g2+3

%R.SKEWNESS = R.CM3./(R.STD.^3);
if (FLAG==-1)
	R = M4N./(n1.*(R.VAR.^2))-3;

elseif (FLAG==0)
	% unbiased estimator according to [3], this is G2 according to [2]
	R = n1.*((k2-3).*(R.N+1)+6)./(max(R.N-2,0).*max(R.N-3,0)) + 3;

elseif (FLAG==1)
	%% method of moments, this is g2 according to [2], a biased estimator
	R = k2;
end

if isa(i,'single')
	R = single(R);
end

% The tests below have been copied from Octave's kurtosis function, 
%   Copyright (C) 1996-2022 The Octave Project Developers
% and adapted by A. Schlögl, 2022

%!test
%! x = [-1; 0; 0; 0; 1];
%! y = [x, 2*x];
%! assert (kurtosis (y), [2.5, 2.5], sqrt (eps));

%!assert (kurtosis ([-3, 0, 1]) == kurtosis ([-1, 0, 3]))
%!assert (kurtosis (ones (3, 5)), NaN (1, 5))
%!assert (kurtosis (1, [], 3), NaN)

%!assert (kurtosis ([1:5 10; 1:5 10],  0, 2),
%!        5.4377317925288901 * [1; 1], 8 * eps)
%!assert (kurtosis ([1:5 10; 1:5 10],  1, 2),
%!        2.9786509002956195 * [1; 1], 8 * eps)
%!assert (kurtosis ([1:5 10; 1:5 10], [], 2),
%!        2.9786509002956195 * [1; 1], 8 * eps)

## Test behavior on single input
%!assert (kurtosis (single ([1:5 10])), single (2.9786511), 3*eps ("single"))
%!assert (kurtosis (single ([1 2]), 0), single (NaN))

## Verify no warnings
%!test
%! lastwarn ("");  # clear last warning
%! kurtosis (1);
%! assert (lastwarn (), "");

## Test input validation
%!error <Invalid call> kurtosis ()
%!error <X must be a numeric vector or matrix> kurtosis (['A'; 'B'])
%!error <FLAG must be 0 or 1> kurtosis (1, 2)
%!error <FLAG must be 0 or 1> kurtosis (1, [1 0])
%!error <DIM must be a positive integer> kurtosis (1, [], ones (2,2))
%!error <DIM must be a positive integer> kurtosis (1, [], 1.5)
%!error <size: DIM must be a positive integer> kurtosis (1, [], 0)

