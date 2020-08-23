function [output] = mat_pow(A,n)
    if n < 0 
        output = zeros(length(A));
    else
        output = A^n;
end