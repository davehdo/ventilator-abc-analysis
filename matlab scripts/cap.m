function [ output_args ] = cap( input_args, cap )
% returns an array that is capped by a specified number
    over_cap = input_args > cap;
    output_args = input_args;
    output_args( over_cap ) = cap;
   
end