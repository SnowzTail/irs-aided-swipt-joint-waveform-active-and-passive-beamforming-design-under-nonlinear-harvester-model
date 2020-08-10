clear; clc; setup; config_distance;

%% ! R-E region vs AP-IRS distance
reSample = cell(length(Variable.horizontalDistance), 1);
reSolution = cell(length(Variable.horizontalDistance), 1);

% * Generate direct channel
[directChannel] = frequency_response(directTapGain, directTapDelay, directDistance, nReflectors, subbandFrequency, fadingMode, 'direct');

for iDistance = 1 : length(Variable.horizontalDistance)
    % * Generate extra channels
    horizontalDistance = Variable.horizontalDistance(iDistance);
    [incidentDistance, reflectiveDistance] = coordinate(directDistance, verticalDistance, horizontalDistance);
    [incidentChannel] = frequency_response(incidentTapGain, incidentTapDelay, incidentDistance, nReflectors, subbandFrequency, fadingMode, 'incident');
    [reflectiveChannel] = frequency_response(reflectiveTapGain, reflectiveTapDelay, reflectiveDistance, nReflectors, subbandFrequency, fadingMode, 'reflective');

    % * Alternating optimization
    [reSample{iDistance}, reSolution{iDistance}] = re_sample(beta2, beta4, directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, nSamples, tolerance);
end
save('data/re_distance.mat');

%% * R-E plots
figure('name', 'R-E region vs AP-IRS horizontal distance');
legendString = cell(length(Variable.horizontalDistance), 1);
for iDistance = 1 : length(Variable.horizontalDistance)
    plot(reSample{iDistance}(1, :) / nSubbands, 1e6 * reSample{iDistance}(2, :));
    legendString{iDistance} = sprintf('d_H = %d', Variable.horizontalDistance(iDistance));
    hold on;
end
hold off;
grid minor;
legend(legendString);
xlabel('Per-subband rate [bps/Hz]');
ylabel('Average output DC current [\muA]');
ylim([0 inf]);
savefig('plots/re_distance.fig');
