% demo_rolling_var_and_mean
% Rich Hakim 2020

% This is a demo for how to use the class rolling_var_and_mean to calculate
% rolling variances and means. It is much faster than calculating the mean or
% std on an entire window every sample. It uses Welford's algorithm to do
% an online recursive update of the values.
% This script allows for an arbitrary number of dimensions to be used, but
% the rolling dimension must be dim 1.
% The object holds onto some values as properties to use for recursive
% calculations and reducing complexity of function calls.

% Note: I haven't figured out how to do efficient setting of large array
% values within objects in Matlab, yet. If you know how to do it, please
% get in touch or send me a pull request!

% How to use:
% 1. construct object
% 2. set_key_properties
% 3. (If doing moving stats) Preallocate a rolling buffer with NaNs
% 3a. buffer dims = [win_size , sizes of dims 2:end of incoming vals]
% 4. start your loop or iterations
% 5. update your rolling buffer of values and (doing moving stats) hold 
% onto the values that are about to be overwritten
% 6. call the step function of the object
% 7. hold onto the outputs
% 
% you can make it go a little bit faster if you replace all the
% test.otherdims{:} with the actual number of ':' in the indexing

%%
% clear
vals = [rand(5000,1000,2) ; rand(5000,1000,2)*3];
win_size = 30*60*4;
% win_size = inf; % comment IN to make it a running (accumulating) calculation
% vals_old = []; % comment IN to make it a running (accumulating) calculation
dim_sizes = size(vals);

statsObj = rolling_var_and_mean();
statsObj = statsObj.set_key_properties(dim_sizes , win_size);

vals_buffer = nan([win_size , statsObj.dim_sizes_slices]); % comment OUT to make it a running (accumulating) calculation

output_mean = nan(size(vals));
output_var = nan(size(vals));
for idx_new = 1:size(vals,1)
    tic
    % % Update rolling buffer of values and get newest values (vals_new) and oldest values (vals_old).
    idx_buffer_new = mod(idx_new-1 , win_size)+1; % comment OUT to make it a running (accumulating) calculation
    vals_old = vals_buffer(idx_buffer_new , statsObj.otherdims{:}); % comment OUT to make it a running (accumulating) calculation
    vals_buffer(idx_buffer_new , statsObj.otherdims{:}) = vals(idx_new,statsObj.otherdims{:}); % comment OUT to make it a running (accumulating) calculation
    vals_new = vals_buffer(idx_buffer_new , statsObj.otherdims{:}); % comment OUT to make it a running (accumulating) calculation
%     vals_new = vals(idx_new); % comment IN to make it a running (accumulating) calculation

    % % Calculate mean and var at new position
    [statsObj , mean_new , var_new] = statsObj.step(idx_new , vals_new , vals_old);
    
    % % Store outputs
    output_mean(idx_new,statsObj.otherdims{:}) = mean_new;
    output_var(idx_new,statsObj.otherdims{:}) = var_new;
    toc
end
%%
figure; hold on;
plot(output_mean(:,1))
plot(sqrt(output_var(:,1)))
