function [qualityFunction] = findPotentialFunction2(wheelchairShapeAngleBig, objectMap, feasibleStates)
    [numRows,numCols] = size(objectMap);
    numAngles = size(wheelchairShapeAngleBig, 3);

    objectMap = gpuArray(objectMap);
    objectDistTF = bwdist(objectMap, 'euclidean').^2; % distance to closest edge, square to bias large gaps
    wheelchairDistTF = bwdist(wheelchairShapeAngleBig ~= 0, 'euclidean').^2; % distance to closest edge, square to bias large gaps
    wheelchairDistTF = gpuArray(wheelchairDistTF);

    measureAll = zeros(numRows,numCols,numAngles);
    for thetaIdx = 1:numAngles
    for r = 1:numRows
    for c = 1:numCols
        % [thetaIdx r c]
        if ~feasibleStates(r,c,thetaIdx)
            measureAll(r,c,thetaIdx) = -Inf;
        else
            [rLow, rHigh] = getIndicies(r, numRows);
            [cLow, cHigh] = getIndicies(c, numCols);
            wheelchairDistTFLocal = wheelchairDistTF(rLow:rHigh, cLow:cHigh, thetaIdx);
            wcAndObjectTF = min(objectDistTF,wheelchairDistTFLocal);
            wcAndObjectTF = wcAndObjectTF.^2;
            nnzwcAndObjectTF = nnz(wcAndObjectTF);
            wcAndObjectTF = sum(wcAndObjectTF(:));
            wcAndObjectTF = wcAndObjectTF ./ nnzwcAndObjectTF;
            measureAll(r,c,thetaIdx) = gather(wcAndObjectTF);
        end
    end % for
    end
    end

    % [cols,rows,thetas] = meshgrid(1:numCols,1:numRows, 1:numAngles);
    % cols = gpuArray(cols);
    % rows = gpuArray(rows);
    % thetas = gpuArray(thetas);
    % wheelchairDistTF = double(wheelchairDistTF);
    % objectDistTF = double(objectDistTF);
    % distTransformSum = @(r, c, theta) getDistTransformSum(wheelchairDistTF, objectDistTF);
    % wcAndObjectTFs = bsxfun(@min, 
    % measureAll = arrayfun(distTransformSum, rows, cols, thetas);

    qualityFunction = gather(measureAll);

end % function

function [freeSpaceQuality] = getDistTransformSum(r, c, thetaIdx, wheelchairDistTF, objectDistTF, feasibleStates);
    [numRows,numCols] = size(objectDistTF);
    if ~feasibleStates(r,c,thetaIdx)
        freeSpaceQuality = -Inf;
    else
        [rLow, rHigh] = getIndicies(r, numRows);
        [cLow, cHigh] = getIndicies(c, numCols);
        wheelchairDistTFLocal = wheelchairDistTF(rLow:rHigh, cLow:cHigh, thetaIdx);
        wcAndObjectTF = min(objectDistTF,wheelchairDistTFLocal);
        freeSpaceQuality = sum(sum(wcAndObjectTF.^2)) / nnz(wcAndObjectTF);
    end
end % function

