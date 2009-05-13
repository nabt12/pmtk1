classdef MixMvnVBEM < ProbDist
 
  % Variational Bayes for a mixture of multivariate normals
  
  properties
    nrestarts;
    % we do not store distributions or mixingDistrib.
    % Instead, we store posterior over their parameters, represented
    % as hyper params - see Bishop ch 10
    % The parameter defining the Dirichlet for the mixingDistrib
    alpha;
    % The following are the parameters for a MvnInvWisharDist()
    mu;
    Sigma;
    dof;
    k;
    covtype;

  end

  methods

    function model = MixMvnVBEM(varargin)
    [model.alpha, model.mu, model.k, model.Sigma, model.dof, model.covtype, model.nrestarts] = processArgs(varargin, ...
      '-alpha', [], ...
      '-mu', [], ...
      '-k', [], ...
      '-Sigma', [], ...
      '-dof', [], ...
      '-covtype', [], ...
      '-nrestarts', 1);
    end

    function model = fit(model, data, varargin)
      %error('not yet implemented')
      K = numel(model.alpha);
      %prior = cell(1,K);
      %for k=1:K
      %  prior{k} = mkPrior(MvnDist('-mu', model.mu(k,:)', '-Sigma', model.Sigma(:,:,k), '-covtype', model.covtype), '-data', data);
      %end
      nrestarts = model.nrestarts;
      param = cell(nrestarts, 1);
      L = zeros(nrestarts, 1);
      for r=1:nrestarts
        [param{r}, L(r)] = VBforMixMvn(model.alpha, model.mu, model.k, model.Sigma, model.dof, model.covtype, data, varargin{:});
      end
      best = argmax(L);
      model.alpha = param{best}.alpha;
      model.mu = param{best}.mu;
      model.Sigma = param{best}.Sigma;
      model.dof = param{best}.dof;
      model.k = param{best}.k;
      %model = gmmVBEM;
    end
    
    function [ph, LL] = conditional(model,data)
      % ph(i,k) = (1/S) sum_s p(H=k | data(i,:),params(s)), a DiscreteDist
      % This is the posterior responsibility of component k for data i
      % LL(i) = log p(data(i,:) | params)  is the log normalization const
    end

     function logp = logprob(model,data)
     end
    

  end % methods

end