function [sample, solution] = re_sample(beta2, beta4, directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, nSamples, tolerance)
    % Function:
    %   - compute the output DC current and rate
    %
    % Input:
    %   - beta2: coefficients on second-order current terms
    %   - beta4: coefficients on fourth-order current terms
    %   - directChannel (h_D) [nSubbands * nTxs * nRxs]: the AP-user channel
    %   - incidentChannel (h_I) [nSubbands * nTxs * nReflectors]: the AP-IRS channel
    %   - reflectiveChannel (h_R) [nSubbands * nReflectors * nRxs]: the IRS-user channel
    %   - txPower (P): average transmit power budget
    %   - noisePower (\sigma_n^2): average noise power
    %   - nCandidates (Q): number of CSCG random vectors to generate
    %   - nSamples (S): number of samples in R-E region
    %   - tolerance (\epsilon): minimum gain ratio per iteration
    %
    % Output:
    %   - sample [2 * nSamples]: rate-energy sample
    %   - solution: waveform and splitting ratio
    %
    % Comment:
    %   - sample R-E region
    %
    % Author & Date: Yang (i@snowztail.com) - 21 Jun 20


    % * Initialize algorithm and set rate constraints
    [capacity, irs, infoAmplitude, powerAmplitude, infoRatio, powerRatio] = wit(directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, tolerance);
    [compositeChannel] = composite_channel(directChannel, incidentChannel, reflectiveChannel, irs);
    [infoWaveform, powerWaveform] = beamform(compositeChannel, infoAmplitude, powerAmplitude);
    rateConstraint = linspace((1 - 1e-3) * capacity, 0, nSamples);

    % * R-E sample
    solution = cell(nSamples, 1);
    sample = zeros(2, nSamples);
    for iSample = 1 : nSamples
        % * Alternating optimization
        isConverged = false;
        current_ = 0;
        while ~isConverged
            [irs] = irs_sdr(beta2, beta4, directChannel, incidentChannel, reflectiveChannel, irs, infoWaveform, powerWaveform, infoRatio, powerRatio, noisePower, rateConstraint(iSample), nCandidates, tolerance);
            [compositeChannel] = composite_channel(directChannel, incidentChannel, reflectiveChannel, irs);
            [infoAmplitude, powerAmplitude, infoRatio, powerRatio, rate, current] = waveform_gp(beta2, beta4, compositeChannel, infoAmplitude, powerAmplitude, infoRatio, powerRatio, txPower, noisePower, rateConstraint(iSample), tolerance);
            [infoWaveform, powerWaveform] = beamform(compositeChannel, infoAmplitude, powerAmplitude);
            isConverged = abs(current - current_) <= tolerance;
            current_ = current;
        end
        sample(:, iSample) = [rate; current];
        solution{iSample}.compositeChannel = compositeChannel;
        solution{iSample}.infoWaveform = infoWaveform;
        solution{iSample}.powerWaveform = powerWaveform;
        solution{iSample}.infoRatio = infoRatio;
        solution{iSample}.powerRatio = powerRatio;
    end

end
