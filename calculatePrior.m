function pathFloatingHippoLabels = calculatePrior(labelPriorType, pathFloatingLabels, logOddsSubfolder, rho, threshold, labelsList, resultsFolder, recompute)

switch labelPriorType
    
    case 'logOdds'
        
        labels2prob(pathFloatingLabels, logOddsSubfolder, rho, threshold, labelsList, recompute);
        pathFloatingHippoLabels = '';
        
    case 'delta function'
        
        pathFloatingHippoLabels = maskHippo(pathFloatingLabels, resultsFolder, recompute);
        
end

end