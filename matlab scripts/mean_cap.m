function [ output_args ] = mean_cap( input_args, cap );
%MEAN_CAP Summary of this function goes here
%   Detailed explanation goes here

    over_cap = input_args > cap;
    output_args = nanmean( [input_args(~over_cap); cap * ones(sum(over_cap),1) ] ); 
end