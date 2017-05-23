function [Path,Xi] = hmmsdecode(Xin,T,hmm,type)
% Computes the state time courses or viterbi paths
%
% INPUTS
% Xin: cell with strings referring to the subject files
% T: cell of vectors, where each element has the length of each trial per
% hmm: the stochastic HMM structure
% type: 0, state time courses; 1, viterbi path
% NOTE: computations of stats now done in getshmmstats.m
%
% Diego Vidaurre, OHBA, University of Oxford (2015)

if nargin<4, type = 0; end

for i = 1:length(T)
    if size(T{i},1)==1, T{i} = T{i}'; end
end

N = length(Xin);
K = length(hmm.state);
TT = []; for i=1:N, TT = [TT; T{i}]; end
tacc = 0; tacc2 = 0;

if length(hmm.train.embeddedlags)>1
    L = -min(hmm.train.embeddedlags) + max(hmm.train.embeddedlags);
    maxorder = 0;
else
    L = hmm.train.maxorder;
    maxorder = hmm.train.maxorder; 
end

if type==0
    Path = zeros(sum(TT)-length(TT)*L,K,'single');
    Xi = zeros(sum(TT)-length(TT)*(L+1),K,K,'single');
else
    Path = zeros(sum(TT)-length(TT)*L,1,'single');
    Xi = [];
end

for i = 1:N
    [X,XX,Y,Ti] = loadfile(Xin{i},T{i},hmm.train);
    XX_i = cell(1); XX_i{1} = XX;
    hmm_i = hmm;
    hmm_i.train.embeddedlags = 0;
    hmm_i.train.pca = 0;
    if isfield(hmm_i.train,'BIGNbatch')
        hmm_i.train = rmfield(hmm_i.train,'BIGNbatch');
    end
    t = (1:(sum(Ti)-length(Ti)*maxorder)) + tacc;
    t2 = (1:(sum(Ti)-length(Ti)*(maxorder+1))) + tacc2;
    tacc = tacc + length(t); tacc2 = tacc2 + length(t2);
    if type==0
        data = struct('X',X,'C',NaN(sum(Ti)-length(Ti)*maxorder,K));
        [gamma,~,xi] = hsinference(data,Ti,hmm_i,Y,[],XX_i);
        checkGamma(gamma,Ti,hmm_i.train,i);
        Path(t,:) = single(gamma);
        Xi(t2,:,:) = xi;
    else
        Path(t,:) = hmmdecode(X,Ti,hmm_i,type,Y);
    end
    
end


end
