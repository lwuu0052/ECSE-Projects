matlab%% ===============================================================
%  ECE3141 — Information and Networks
%  Short Project: CDMA Signal Spreading and Recovery
%                 using Walsh-Hadamard Codes
% ---------------------------------------------------------------
%  Authors:
%    Wu Li Min      (Student ID: 34478841)
%    Lee Guo-Yi     (Student ID: 34475761)
%
%  Date:       17th May 2026
%
%  Description:
%    This script simulates a two-user CDMA system using 8-bit
%    Walsh-Hadamard spreading codes and BPSK modulation. It
%    investigates the effects of:
%      1. AWGN noise on bit recovery (BER vs Eb/N0)
%      2. Imperfect power control (near-far problem)
%      3. Imperfect synchronisation (timing offsets)
%
%  Outputs (Figures):
%    Fig. 10 — Chip waveforms (no noise)
%    Fig. 11 — Combined channel with AWGN
%    Fig. 12 — BER vs SNR (Monte Carlo)
%    Fig. 13 — BER under imperfect power control
%    Fig. 14 — Cross-correlation leakage vs timing offset
%
%  Usage:
%    Run the script and enter binary strings for each user
%    when prompted (e.g., "101" for User 1, "010" for User 2).
%% ===============================================================

clear;
clc;
close all;
%% ---------------------------------------------------------------
%  Setup & Parameters
% ---------------------------------------------------------------
len_spreading_code = 8;        % Spreading code length (Walsh-Hadamard)
num_users = 2;        % Number of users
snr_vec = 0:2:20;   % SNR sweep range in dB
num_trials = 500;      % Monte Carlo trials per SNR point
power_gains = [0.5, 2.0]; % User 1: weak (-6dB), User 2: strong (+6dB)
SNR_demo = [2 5];    % Two SNR levels to test
upsample_factor = 8;        % For fractional sync offsets

%% ---------------------------------------------------------------
%  User Input
% ---------------------------------------------------------------
data = [];
for i = 1:num_users
    input_string = input(sprintf('User %d — Enter binary string (e.g. 101): ', i), 's');
    input_string = strrep(input_string, ' ', ''); % Remove spaces
    data(i, :) = double(input_string) - double('0'); % Convert string to numbers
end

%% ---------------------------------------------------------------
%  BPSK Modulation:  bit 0 -> +1,  bit 1 -> -1
% ---------------------------------------------------------------
bpsk = 1 - 2 * data; 

%% ---------------------------------------------------------------
%  Walsh-Hadamard Codes
% ---------------------------------------------------------------
walsh_table = hadamard(len_spreading_code); % Generate 8x8 Hadamard matrix
walsh_codes = walsh_table(1:num_users, :);  % One code per user

fprintf('============================================================\n');
fprintf('Walsh-Hadamard codes\n');
fprintf('============================================================\n');
disp(walsh_codes);

%% ---------------------------------------------------------------
%  Orthogonality Check
% ---------------------------------------------------------------
fprintf('============================================================\n');
fprintf('Orthogonality check\n');
fprintf('============================================================\n');
for i = 1:num_users
    for j = 1:num_users
        result = dot(walsh_codes(i,:), walsh_codes(j,:)); % Dot product of two codes
        fprintf("W%d · W%d = %+3d |\n", i, j, result); % 0 = orthogonal, N = same code
    end
end

%% ---------------------------------------------------------------
%  Spreading — each bit expanded into chips
% ---------------------------------------------------------------
[rows, num_bits] = size(bpsk); % rows = users, num_bits = bits per user
total_chips = num_bits * len_spreading_code; % Total chips in the signal
chips = zeros(num_users, total_chips);  % Initialise chip array

for i = 1:num_users
    for j = 1:num_bits
        idx = (j-1)*len_spreading_code + 1 : j*len_spreading_code; % Chip range for bit j
        chips(i, idx) = bpsk(i,j) * walsh_codes(i,:); % Multiply bit by Walsh code
    end
end

fprintf('============================================================\n');
fprintf('Spreading — data bits converted to chip sequences\n');
fprintf('============================================================\n');
disp(chips);

%% ---------------------------------------------------------------
%  Combine all users into one common channel
% ---------------------------------------------------------------
common_channel = sum(chips, 1); % Sum all users column by column

fprintf('============================================================\n');
fprintf('Common Channel (Sum of all spread signals)\n');
fprintf('============================================================\n');
disp(common_channel);

%% ---------------------------------------------------------------
%  Figure 10 — Chip Waveforms
% ---------------------------------------------------------------
figure(10)
t = 1:total_chips; % X axis: chip index
for i = 1:num_users
    subplot(num_users + 1, 1, i)
    stairs(t, chips(i,:), 'LineWidth', 1.5) % Staircase plot for square wave chips
    ylim([-1.5 1.5]); yticks([-1 0 1])
    ylabel(sprintf('User %d', i))
    title(sprintf('User %d — chip sequence  (Walsh code W%d)', i, i), 'FontWeight', 'normal')
    grid on
end
subplot(num_users + 1, 1, num_users + 1)
stairs(t, common_channel, 'r', 'LineWidth', 1.5) % Combined channel in red
ylim([min(common_channel)-0.5  max(common_channel)+0.5])
ylabel('Sum'); xlabel('Chip index')
title('Combined channel — sum of all users', 'FontWeight', 'normal')
grid on
sgtitle('CDMA chip waveforms — no noise')

%% ---------------------------------------------------------------
%  Decoding (No Noise)
% ---------------------------------------------------------------
decoded_no_noise = zeros(num_users, num_bits); % Initialise decoded output
for i = 1:num_users
    for j = 1:num_bits
        idx = (j-1)*len_spreading_code + 1 : j*len_spreading_code; % Chip range for bit j
        corr_val = sum(common_channel(idx) .* walsh_codes(i,:)); % Despread with Walsh code
        decoded_no_noise(i,j) = corr_val < 0; % Negative = bit 1, Positive = bit 0
    end
end

fprintf('============================================================\n');
fprintf('Comparison of input and output\n');
fprintf('============================================================\n');
fprintf('%-10s | %-15s | %-15s | %-10s\n', 'User', 'Original Data', 'Decoded Data', 'Status');
fprintf('------------------------------------------------------------\n');
for i = 1:num_users
    orig_str = num2str(data(i,:), '%d');
    deco_str = num2str(decoded_no_noise(i,:), '%d');
    if isequal(data(i,:), decoded_no_noise(i,:))
        status = 'SUCCESS';
    else
        status = 'ERROR';
    end
    fprintf('User %d    | %-15s | %-15s | %-10s\n', i, orig_str, deco_str, status);
end
fprintf('============================================================\n');

%% ---------------------------------------------------------------
%  Figure 11 — AWGN Demo
% ---------------------------------------------------------------
fprintf('============================================================\n')
fprintf('AWGN noise demo — decoding at two SNR levels\n')
fprintf('============================================================\n')
fprintf('%-10s | %-10s | %-10s\n', 'SNR (dB)', 'User', 'BER')
fprintf('------------------------------------------------------------\n')

BER_demo = zeros(length(SNR_demo), num_users);
for snr_count = 1:length(SNR_demo)
    curr_snr     = SNR_demo(snr_count);       % Current SNR value
    snr_per_chip = curr_snr - 10*log10(len_spreading_code); % Adjust SNR per chip
    noisy_channel = awgn(common_channel, snr_per_chip, 'measured'); % Add AWGN noise
    for i = 1:num_users
        errors = 0; % Reset error count
        for j = 1:num_bits
            idx = (j-1)*len_spreading_code + 1 : j*len_spreading_code;
            corr_val = sum(noisy_channel(idx) .* walsh_codes(i,:)); % Despread
            decoded_bit = corr_val < 0; % Decode bit
            if decoded_bit ~= data(i,j); errors = errors + 1; end % Count error
        end
        BER_demo(snr_count, i) = errors / num_bits; % BER = errors / total bits
        fprintf('%-10d | User %-4d | %.4f\n', curr_snr, i, BER_demo(snr_count,i))
    end
end
fprintf('============================================================\n')

snr_vis   = SNR_demo(1) + 10*log10(num_users) - 10*log10(len_spreading_code);
noisy_vis = awgn(common_channel, snr_vis, 'measured'); % Noisy signal at SNR=2dB for plot

figure(11)
subplot(2,1,1) % Top plot: clean signal
stairs(1:total_chips, common_channel, 'b', 'LineWidth', 1.5)
ylim([min(common_channel)-1  max(common_channel)+1])
ylabel('Amplitude')
title('Combined channel — no noise', 'FontWeight', 'normal'); grid on

subplot(2,1,2) % Bottom plot: noisy vs clean
plot(1:total_chips, noisy_vis, 'r', 'LineWidth', 0.8); 
hold on % Noisy signal in red
stairs(1:total_chips, common_channel, 'b--', 'LineWidth', 1.2); 
hold off % Clean reference
ylabel('Amplitude'); xlabel('Chip index')
legend('Noisy', 'Clean', 'Location', 'northeast')
title(sprintf('Combined channel — AWGN added  (SNR = %d dB)', SNR_demo(1)), 'FontWeight', 'normal')
grid on
sgtitle('Effect of AWGN on the combined CDMA channel')

%% ---------------------------------------------------------------
%  Figure 12 — BER vs SNR Monte Carlo
% ---------------------------------------------------------------
BER_simulation  = zeros(1, length(snr_vec)); % Simulated BER array
BER_theoretical = zeros(1, length(snr_vec)); % Theoretical BER array

for snr_iter = 1:length(snr_vec)
    curr_snr     = snr_vec(snr_iter); % Current SNR value (dB)
    snr_per_chip = curr_snr + 10*log10(num_users) - 10*log10(len_spreading_code);
    bit_errors   = 0; % Reset error count
    for trial = 1:num_trials % Monte Carlo: repeat 500 times
        noisy_channel = awgn(common_channel, snr_per_chip, 'measured'); % Fresh noise each trial
        for i = 1:num_users
            for j = 1:num_bits
                idx         = (j-1)*len_spreading_code + 1 : j*len_spreading_code;
                corr_val    = sum(noisy_channel(idx) .* walsh_codes(i,:)); % Despread
                decoded_bit = corr_val < 0; % Decode bit
                if decoded_bit ~= data(i,j); bit_errors = bit_errors + 1; end % Count error
            end
        end
    end
    total_bits                = num_trials * num_bits * num_users; % Total bits across all trials
    BER_simulation(snr_iter)  = bit_errors / total_bits;           % Simulated BER
    snr_linear                = 10^(curr_snr/10);                  % Convert dB to linear
    BER_theoretical(snr_iter) = 0.5 * erfc(sqrt(snr_linear));     % Theoretical BPSK BER
end

fprintf('============================================================\n')
fprintf('\nSNR(dB)  Simulated_BER  Theoretical_BER\n')
for snr_iter = 1:length(snr_vec)
    fprintf(num2str([snr_vec(snr_iter) BER_simulation(snr_iter) ...
                     BER_theoretical(snr_iter)], '%-8.0f  %-13.5f  %.5f'))
    disp(' ')
end
fprintf('============================================================\n')

figure(12) % semilogy makes the Y-axis logarithmic
semilogy(snr_vec, BER_simulation,  'bo-', 'LineWidth', 1.8, 'MarkerSize', 7, 'MarkerFaceColor', 'b')
hold on
semilogy(snr_vec, BER_theoretical, 'r--', 'LineWidth', 1.8)
hold off
grid on
xlabel('E_b/N_0 (dB)'); ylabel('Bit Error Rate (BER)')
title('The effect of noise on the combined signal')
legend('Simulated (CDMA)', 'Theoretical (BPSK)', 'Location', 'southwest')
ylim([1e-6 1]); xlim([snr_vec(1) snr_vec(end)])

%% ---------------------------------------------------------------
%  Figure 13 — Imperfect Power Control
% ---------------------------------------------------------------
fprintf('\n============================================================\n')
fprintf('Imperfect power control — gain per user:\n')
for i = 1:num_users
    fprintf('  User %d : gain = %.1f  (%.1f dB)\n', i, power_gains(i), 20*log10(power_gains(i)))
end
fprintf('============================================================\n')

chips_power = zeros(num_users, total_chips); % Initialise power-scaled chips
for i = 1:num_users
    chips_power(i,:) = power_gains(i) * chips(i,:); % Scale each user by power gain
end
channel_power = sum(chips_power, 1); % Combined power-imbalanced channel
BER_power     = zeros(num_users, length(snr_vec)); % BER matrix: rows=users, cols=SNR

for snr_iter = 1:length(snr_vec)
    curr_snr      = snr_vec(snr_iter); % Current SNR value
    snr_per_chip  = curr_snr + 10*log10(sum(power_gains.^2)) - 10*log10(len_spreading_code);
    errors_power  = zeros(1, num_users); % Reset errors for all users
    for trial = 1:num_trials % Monte Carlo: 500 trials
        noisy_channel = awgn(channel_power, snr_per_chip, 'measured'); % Add noise
        for i = 1:num_users
            for j = 1:num_bits
                idx         = (j-1)*len_spreading_code + 1 : j*len_spreading_code;
                corr_val    = sum(noisy_channel(idx) .* walsh_codes(i,:)); % Despread
                decoded_bit = corr_val < 0;
                if decoded_bit ~= data(i,j)
                    errors_power(i) = errors_power(i) + 1; % Count error per user
                end
            end
        end
    end
    for i = 1:num_users
        BER_power(i, snr_iter) = errors_power(i) / (num_trials * num_bits); % BER per user
    end
end


figure(13)
for i = 1:num_users
    semilogy(snr_vec, BER_power(i,:), '-o', ...
             'LineWidth', 1.6, 'MarkerSize', 7, 'MarkerFaceColor', 'auto', ...
             'DisplayName', sprintf('User %d  (gain=%.1f)', i, power_gains(i)))
    hold on
end
semilogy(snr_vec, BER_theoretical, 'r--', 'LineWidth', 1.8, ...
         'DisplayName', 'Theoretical BPSK (perfect power)')
hold off
grid on
xlabel('E_b/N_0 (dB)'); ylabel('Bit Error Rate (BER)')
title('BER vs SNR — effect of imperfect power control')
legend('show', 'Location', 'southwest')
ylim([1e-5 1]); xlim([snr_vec(1) snr_vec(end)])

%% ---------------------------------------------------------------
%  Imperfect Synchronisation — integer and fractional chip offsets
% ---------------------------------------------------------------
offsets_chips   = -2:0.1:2;  % Increased density (0.1) for smoother curve
victim_user     = 1;          % The user whose timing drifts
interfered_user = 2;          % The user we are monitoring for errors
leakage         = zeros(1, length(offsets_chips));
BER_sync        = zeros(1, length(offsets_chips));

W_interfered = walsh_codes(interfered_user, :); % Walsh code of interfered user
u            = upsample_factor;                 % Upsample factor for fractional offsets

num_bits_sync   = 500; % Long sequence for low BER variance
num_trials_sync = 30;  % Monte Carlo trials per offset point
snr_sync_dB     = 6;   % Fixed SNR for synchronisation analysis

for off_idx = 1:length(offsets_chips)
    offset        = offsets_chips(off_idx);
    shift_samples = round(offset * u); % Convert chip offset to sample offset

    trial_leakage = zeros(1, num_trials_sync);
    trial_BER     = zeros(1, num_trials_sync);

    for tr = 1:num_trials_sync
        rng(tr * 1000 + off_idx); % Fresh random bits each trial (fixed seed for reproducibility)
        data_sync = randi([0 1], num_users, num_bits_sync);
        bpsk_sync = 1 - 2*data_sync; % BPSK modulation

        % Spread all users
        total_chips_sync = num_bits_sync * len_spreading_code;
        chips_sync = zeros(num_users, total_chips_sync);
        for i = 1:num_users
            for j = 1:num_bits_sync
                idx = (j-1)*len_spreading_code + 1 : j*len_spreading_code;
                chips_sync(i,idx) = bpsk_sync(i,j) * walsh_codes(i,:);
            end
        end

        % Upsample victim and other users separately
        victim_up = repelem(chips_sync(victim_user,:), u);
        other_up  = zeros(1, total_chips_sync * u);
        for i = 1:num_users
            if i ~= victim_user
                other_up = other_up + repelem(chips_sync(i,:), u);
            end
        end

        % Apply timing offset to victim using circshift (periodic shift)
        shifted_victim_up = circshift(victim_up, shift_samples);

        % Combine shifted victim + perfectly-sync'd other users, then add noise
        combined_up  = shifted_victim_up + other_up;
        snr_adjusted = snr_sync_dB - 10*log10(u) - 10*log10(num_users); % Correct for upsampling
        noisy_up     = awgn(combined_up, snr_adjusted, 'measured');

        % Downsample: sample at centre of each chip period
        sample_idx = round(u/2) : u : (total_chips_sync * u);
        sample_idx = sample_idx(sample_idx <= length(noisy_up));
        rx_ds      = noisy_up(sample_idx);
        victim_ds  = shifted_victim_up(sample_idx);

        % Pad if needed to ensure full length
        if length(rx_ds) < total_chips_sync
            rx_ds(end+1:total_chips_sync)     = 0;
            victim_ds(end+1:total_chips_sync) = 0;
        end

        % Evaluate middle window only — skip guard bits at edges to avoid wrap-around
        guard  = 20;
        eval_s = guard + 1;
        eval_e = num_bits_sync - guard;
        n_eval = eval_e - eval_s + 1;

        bit_errors = 0;
        acc_leak   = 0;
        for j = eval_s:eval_e
            chip_idx = (j-1)*len_spreading_code + 1 : j*len_spreading_code;

            % Cross-correlation leakage: MAI from victim into interfered user's correlator
            acc_leak = acc_leak + ...
                abs(sum(victim_ds(chip_idx) .* W_interfered)) / len_spreading_code;

            % BER for interfered user
            corr_val    = sum(rx_ds(chip_idx) .* W_interfered);
            decoded_bit = corr_val < 0; % BPSK decision: negative = bit 1
            if decoded_bit ~= data_sync(interfered_user, j)
                bit_errors = bit_errors + 1;
            end
        end

        trial_leakage(tr) = acc_leak / n_eval; % Average leakage for this trial
        trial_BER(tr)     = bit_errors / n_eval; % BER for this trial
    end

    leakage(off_idx)  = mean(trial_leakage); % Average over all trials
    BER_sync(off_idx) = mean(trial_BER);
end

% Print results table
fprintf('\n============================================================\n')
fprintf('Imperfect synchronisation results\n')
fprintf('Victim: User %d   Interfered: User %d\n', victim_user, interfered_user)
fprintf('============================================================\n')
fprintf('%-20s | %-18s | %-10s\n', 'Offset (chip periods)', 'Leakage (avg)', 'BER')
fprintf('------------------------------------------------------------\n')
for k = 1:length(offsets_chips)
    fprintf('%-20.2f | %-18.4f | %.4f\n', offsets_chips(k), leakage(k), BER_sync(k))
end
fprintf('============================================================\n')

%% ---------------------------------------------------------------
%  Figure 14 — Synchronisation Plot
% ---------------------------------------------------------------
figure(14)

subplot(2,1,1) % Top: leakage vs offset
plot(offsets_chips, leakage, 'ms-', 'LineWidth', 1.8, ...
     'MarkerFaceColor', 'm', 'MarkerSize', 6)
hold on
zero_idx = find(abs(offsets_chips) < 1e-9); % Find perfect sync point
plot(0, leakage(zero_idx), 'ko', 'MarkerSize', 10, 'LineWidth', 1.5, ...
     'DisplayName', 'Perfect sync (offset = 0)')
hold off
xlabel('Timing offset (chip periods)')
ylabel('Average cross-correlation leakage')
title(sprintf('Cross-correlation leakage into User %d from shifted User %d', ...
              interfered_user, victim_user), 'FontWeight', 'normal')
legend('Leakage', 'Perfect sync', 'Location', 'best')
ylim([0 0.25])
grid on

subplot(2,1,2) % Bottom: BER vs offset
bar(offsets_chips, BER_sync, 0.5, 'FaceColor', [0.3 0.6 0.9])
hold on
ref_BER = 0.5 * erfc(sqrt(10^(snr_sync_dB/10))); % Theoretical BER at fixed SNR
yline(ref_BER, 'r--', sprintf('Theoretical BER @ %d dB', snr_sync_dB), ...
      'LabelHorizontalAlignment', 'left', 'LineWidth', 1.5)
hold off
xlabel('Timing offset (chip periods)')
ylabel('BER')
ylim([0 0.6])
title(sprintf('User %d BER vs timing offset of User %d', ...
              interfered_user, victim_user), 'FontWeight', 'normal')
grid on
sgtitle(sprintf('Effect of imperfect synchronisation  (spreading code length = %d chips)', ...
                len_spreading_code))