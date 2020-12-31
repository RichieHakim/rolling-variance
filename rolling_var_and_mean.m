% """
% Rich Hakim 2020
% Most of this code uses a version of Welford's algorithm and
% was adapted from some Python code I found here: 
% http://www.taylortree.com/2010/11/running-variance.html 
% and here: 
% http://www.taylortree.com/2010/06/running-simple-moving-average-sma.html
% and here:
% http://subluminal.wordpress.com/2008/07/31/running-standard-deviations/
% 
% The purpose of this script is to compute very fast rolling variances
% and means in a stepwise way. This allows for online processing of
% incoming data. It uses a recursive algorithm to calculate online
% updates to the current std and mean.

% The only challenge is setting up a rolling buffer of values, which must
% be done outside of this class. See the demo script for an example.
% Note: I haven't figured out how to do efficient setting of large array
% values within objects in Matlab, yet. If you know how to do it, please
% get in touch or send me a pull request!

% RUNNING (accumulating) vs. ROLLING (windowed):
% In order to use it as a running (accumulating from the first index)
% average or variance, just set win_size to be inf and vals_old to []. This
% method can be used to calculate normal variances and means of arrays that
% are too big to fit into memory!

% ARBITRARY DIMENSIONS:
% This script allows for an arbitrary number of dimensions to be used, but
% the rolling dimension must be dim 1.

classdef rolling_var_and_mean
    properties
        varSum_old = [];
        mean_old = [];
        win_size = 3;
        dim_sizes_slices = [1];
        %         vals_rolling = nan([win_size, dim_sizes_slices]);
        vals_rolling = nan([3, 1]);
        otherdims = repmat({':'},1,numel(1)-1);
    end
    
    methods
        
        % SETUP
        function obj = set_key_properties(obj, dim_sizes , win_size)
            %     """
            %     This function sets the key properties needed to starting using the step function and other functions
            %     dim_sizes = sizes of dimensions in input data. The first dimension doesnt really matter since it is the rolling dimension, and it can be set to 1 or anything.
            %     win_size = this is the size of the rolling window
            %     """
            obj.dim_sizes_slices = dim_sizes(2:end);
            %             obj.vals_rolling = nan([win_size , obj.dim_sizes_slices]);
            obj.otherdims = repmat({':'},1,numel(obj.dim_sizes_slices));
            obj.win_size = win_size;
        end
        
        % MAIN STEP FUNCTION:
        function [obj , mean_new , var_new]  = step(obj, idx_new, vals_new , vals_old)
            %             idx_rolling_new = mod(idx_new-1 , obj.win_size)+1;
            %             vals_old = obj.vals_rolling(idx_rolling_new , obj.otherdims{:});
            %             obj.vals_rolling(idx_rolling_new , obj.otherdims{:}) = vals;
            %             vals_new = obj.vals_rolling(idx_rolling_new , obj.otherdims{:});
            mean_new = obj.update_mean(idx_new, vals_new, vals_old, obj.win_size, obj.mean_old);
            varSum_new = obj.update_varSum(idx_new, vals_new, vals_old, obj.win_size, obj.varSum_old);
            var_new = obj.varSum_to_var(idx_new, obj.win_size, mean_new, varSum_new, obj.dim_sizes_slices);
            
            obj.mean_old = mean_new;
            obj.varSum_old = varSum_new;
        end
        
        % Code for the Running or Windowed Variance:
        function varSum_new = update_varSum(obj, idx_new, vals_new, vals_old, win_size, varSum_old)
            %     """
            %     Returns the power sum average based on the blog post from
            %     Subliminal Messages.  Use the power sum average to help derive the running
            %     variance.
            %     sources: http://subluminal.wordpress.com/2008/07/31/running-standard-deviations/
            %
            %     Keyword arguments:
            %     idx_new     --  current index or location of the value in the vals
            %     vals  --  list or tuple of data to average
            %     win_size  -- number of values to include in average
            %     varSum_old    --  previous update_varSum (n - 1) of the vals.
            %     """
            
            if win_size < 1
                warning ValueError("win_size must be 1 or greater")
            end
            if idx_new < 1
                idx_new = 1;
            end
            if isempty(varSum_old)
                if idx_new > 1
                    warning ValueError("varSum_old of NaN when idx_new > 1")
                end
                varSum_old = 0.0;
            end
            vals_new = double(vals_new);
            
            if idx_new <= win_size
                % CODE MEAT
                varSum_new = varSum_old + (vals_new .* vals_new - varSum_old) ./ (idx_new);
            else
                vals_old = double(vals_old);
                % CODE MEAT
                varSum_new = varSum_old + (((vals_new .* vals_new) - (vals_old .* vals_old)) ./ win_size);
            end
        end
        
        % Code for converting varSum to var
        function var_new = varSum_to_var(obj, idx_new, win_size, mean_current, varSum, dim_sizes_slices)
            %     """
            %     Returns the running variance based on a given time win_size.
            %     sources: http://subluminal.wordpress.com/2008/07/31/running-standard-deviations/
            %
            %     Keyword arguments:
            %     idx_new     --  current index or location of the value in the vals
            %     vals  --  list or tuple of data to average
            %     mean_current    --  current average of the given win_size
            %     varSum -- current varSum of the given win_size
            %     """
            if win_size < 1
                warning ValueError("win_size must be 1 or greater")
            end
            if idx_new <= 1
                var_new = zeros([1 , dim_sizes_slices]);
            else
                if isempty(mean_current)
                    warning ValueError("mean_current of None invalid when idx_new > 0")
                end
                if isempty(varSum)
                    warning ValueError("varSum of None invalid when idx_new > 0")
                end
                if idx_new >= win_size
                    windowsize = win_size;
                else
                    windowsize = idx_new;
                end
                % CODE MEAT
                var_new = (varSum .* windowsize - windowsize .* mean_current .* mean_current) ./ (windowsize-1);
            end
        end
        
        %% 
        % Code for the Running Mean:
        function mean_new = running_mean(obj, idx_new, vals, mean_old)
            %     """
            %     Returns the cumulative or unweighted simple moving average.
            %     Avoids sum of vals per call.
            %
            %     Keyword arguments:
            %     idx_new     --  current index or location of the value in the vals
            %     vals  --  list or tuple of data to average
            %     mean_old  --  previous average (n - 1) of the vals.
            %     """
            
            if idx_new <= 1
                mean_new = vals;
            else
                % CODE MEAT
                mean_new = mean_old + ((vals - mean_old) / (idx_new));
            end
        end
        
        % Code for the Windowed mean:
        function mean_new = update_mean(obj, idx_new, vals_new, vals_old, win_size, mean_old)
            %     """
            %     Returns the running simple moving average - avoids sum of vals per call.
            %
            %     Keyword arguments:
            %     idx_new     --  current index or location of the value in the vals
            %     vals  --  list or tuple of data to average
            %     win_size  --  number of values to include in average
            %     mean_old  --  previous simple moving average (n - 1) of the vals
            %     """
            
            if win_size < 1
                warning ValueError("win_size must be 1 or greater")
            end
            
            if idx_new <= 1
                mean_new = vals_new;
            elseif idx_new <= win_size
                mean_new = obj.running_mean(idx_new, vals_new, mean_old);
            else
                % CODE MEAT
                mean_new = mean_old + ((vals_new - vals_old) ./ double(win_size));
            end
        end
        
    end
    
end
