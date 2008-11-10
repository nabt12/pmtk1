classdef MultinomDist < VecDist
  
  properties
    N; 
    mu;
  end
  
  
  %% Main methods
  methods 
    function obj =  MultinomDist(N,mu)
      if nargin == 0;
        N = []; mu = [];
      end
      obj.N = N;
      obj.mu = mu;
    end
    
    function plot(obj) % over-ride default
      figure; bar(obj.mu);
      title(sprintf('Mu(%d,:)', obj.N))
    end
  
    
    function m = mean(obj)
     checkParamsAreConst(obj)
      m = obj.N * obj.mu;
    end
    
   
    function X = sample(obj, n)
       % X(i,:) = random vector (of length ndims) of ints that sums to N, for i=1:n
       checkParamsAreConst(obj)
       if nargin < 2, n = 1; end
       if statsToolboxInstalled
          X = mnrnd(obj.N, obj.mu, n);
       else
         p = repmat(obj.mu(:), 1, n);
         X = sample_hist(p, obj.N)';
       end
     end
    
     function logp = logprob(obj, X)
       % p(i) = log p(X(i,:))
       checkParamsAreConst(obj)
       n = size(X,1);
       p = repmat(obj.mu,n,1);
       xlogp = sum(X .* log(p), 2);
       logp = factorialln(obj.N) - sum(factorialln(X), 2) + xlogp; 
       % debugging
       %logp2 = log(mnpdf(X,obj.mu));
       %assert(approxeq(logp, logp2))
     end


     function logZ = lognormconst(obj)
       logZ = 0;
     end
     
     function mm = marginal(m, queryVars)
      % p(Q)
      checkParamsAreConst(obj)
      dims = queryVars;
      mm = MultinomDist(m.N, m.mu(dims));
     end
    
     
     function obj = fit(obj, varargin)
       % m = fit(model, 'name1', val1, 'name2', val2, ...)
       % Arguments are
       % data - data(i,:) = vector of counts for trial i
       % suffStat - SS.counts(j), SS.N = total amount of data
       % method -  'map' or 'mle' or 'bayesian'
       [X, suffStat, method] = process_options(...
         varargin, 'data', [], 'suffStat', [], 'method', 'mle');
       if isempty(suffStat), suffStat = MultinomDist.mkSuffStat(X); end
       switch method
         case 'mle'
           obj.mu =  suffStat.counts / suffStat.N;
         case 'map'
           switch class(obj.mu)
             case 'DirichletDist'
               d = ndims(obj);
               obj.mu  = (suffStat.counts + obj.alpha - 1) / (suffStat.N + sum(obj.alpha) - d);
             otherwise
               error(['cannot handle mu of type ' class(obj.mu)])
           end
         case 'bayesian'
             obj = fitBayesian(obj,varargin{:});
         otherwise
           error(['unknown method ' method])
       end
     end

     
     
  end



  %% static
  methods(Static = true)
      function SS = mkSuffStat(X)
       SS.counts = sum(X,2);
       n = size(X,1);
       SS.N = sum(X(:));
      end
       
  end
  
  %% Private methods
  methods(Access = 'protected')
   
    function checkParamsAreConst(obj)
      p = isa(obj.mu, 'double') && isa(obj.N, 'double');
      if ~p
        error('parameters must be constants')
      end
    end
    
    function obj = fitBayesian(obj, varargin)
       % m = fitBayesian(model, 'name1', val1, 'name2', val2, ...)
       % Arguments are
       % data - data(i,:) = vector of counts for trial i
       % suffStat - SS.counts(j), SS.N = total amount of data
       [X, suffStat] = process_options(...
         varargin, 'data', [], 'suffStat', []);
       if isempty(suffStat), suffStat = MultinomDist.mkSuffStat(X); end
       switch class(obj.mu)
         case 'DirichletDist'
           obj.mu = DirichletDist(obj.mu.alpha + suffStat.counts);
         otherwise
           error(['cannot handle mu of type ' class(obj.mu)])
       end
     end

  end
  
end