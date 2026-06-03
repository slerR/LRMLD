%% RM_16_11
clear; clc;

cfg = struct();

cfg.L     = 16;
cfg.LLR_W = 6;
cfg.FSM   = 0;

% ключ 'default'
cfg.MakeTables = struct('key', 'default', 'table', [
    "0000", "1111";
    "1011", "0100";
    "1101", "0010";
    "0110", "1001";
    "1110", "0001";
    "0101", "1010";
    "0011", "1100";
    "1000", "0111"
]);

% ключ 'default'
cfg.CombTables = struct('key', 'default', 'table', [
    0 0 0; 0 5 5; 0 3 3; 0 6 6;
    1 2 2; 1 7 7; 1 1 1; 1 4 4;
    2 6 3; 2 3 6; 2 5 0; 2 0 5;
    3 4 1; 3 1 4; 3 7 2; 3 2 7;
    4 6 0; 4 5 6; 4 3 5; 4 0 6;
    5 4 2; 5 1 7; 5 7 1; 5 2 4;
    6 0 3; 6 5 6; 6 3 0; 6 6 5;
    7 2 1; 7 7 4; 7 1 2; 7 4 7
]);

cfg.SECT = {
    [0 4; 4 8; 8 12; 12 16];
    [0 8; 8 16];
    [0 16]
};

gen_top('C:\LRMLD\decoders\RM_N16_K11\top_16_L16_fsm0.sv',cfg);
%% N = 16, asym
clear; clc;

cfg = struct();

cfg.L     = 3;
cfg.LLR_W = 6;
cfg.FSM   = 0;

% ключ 'default'
cfg.MakeTables(1) = struct('key', 'default', 'table', [
    "0000", "1111", "1011", "0100"; ...
    "1101", "0010", "0110", "1001";
    "1110", "0001", "0101", "1010"; ...
    "0011", "1100", "1000", "0111"
]);

cfg.MakeTables(2).key   = '0_2';
cfg.MakeTables(2).table = [
    "00";
    "10";
    "11";
    "01"
];

cfg.MakeTables(3).key   = '2_4';
cfg.MakeTables(3).table = [
    "00";
    "10";
    "11";
    "01"
];

cfg.CombTables = struct('key', 'default', 'table', [
    0 0 0; 0 3 3;
    1 1 1; 1 2 2; 
    2 1 2; 2 2 1; 
    3 3 0; 3 0 3; 
]);

cfg.SECT = {
    [0 2; 2 4; 4 8; 8 12];
    [0 4; 4 12];
    [0 12; 12 16];
    [0 16]
};

gen_top('C:\LRMLD\decoders\RM_N16_K11\top_16_asym.sv',cfg);
%% RM_32_16
clear; clc;

cfg = struct();

cfg.L     = 16;
cfg.LLR_W = 8;
cfg.FSM   = 0;

cfg.module_name = 'top_32';

cfg.MakeTables = struct('key', 'default', 'table', [
    "0000", "1111";
    "1011", "0100";
    "1101", "0010";
    "0110", "1001";
    "1110", "0001";
    "0101", "1010";
    "0011", "1100";
    "1000", "0111"
]);

cfg.CombTables = struct('key', 'default', 'table', [
    0 0 0; 0 5 5; 0 3 3; 0 6 6;
    1 2 2; 1 7 7; 1 1 1; 1 4 4;
    2 6 3; 2 3 6; 2 5 0; 2 0 5;
    3 4 1; 3 1 4; 3 7 2; 3 2 7;
    4 6 0; 4 5 6; 4 3 5; 4 0 6;
    5 4 2; 5 1 7; 5 7 1; 5 2 4;
    6 0 3; 6 5 6; 6 3 0; 6 6 5;
    7 2 1; 7 7 4; 7 1 2; 7 4 7
]);

cfg.SECT = {
    [0 4; 4 8; 8 12; 12 16; 16 20; 20 24; 24 28; 28 32];
    [0 8; 8 16; 16 24; 24 32];
    [0 16; 16 32]
    [0 32]
};

gen_top('C:\LRMLD\decoders\RM_N32_K16\top_32_L16_fsm0.sv',cfg);


%% нессиметричка N = 64
clear; clc;

cfg = struct();
cfg.L     = 5;
cfg.LLR_W = 6;
cfg.FSM   = 3;

cfg.module_name = 'top_64';

cfg.MakeTables = struct('key', 'default', 'table', [
    "0000", "1111";
    "1011", "0100";
    "1101", "0010";
    "0110", "1001";
    "1110", "0001";
    "0101", "1010";
    "0011", "1100";
    "1000", "0111"
]);

cfg.CombTables = struct('key', 'default', 'table', [
    0 0 0; 0 5 5; 0 3 3; 0 6 6;
    1 2 2; 1 7 7; 1 1 1; 1 4 4;
    2 6 3; 2 3 6; 2 5 0; 2 0 5;
    3 4 1; 3 1 4; 3 7 2; 3 2 7;
    4 6 0; 4 5 6; 4 3 5; 4 0 6;
    5 4 2; 5 1 7; 5 7 1; 5 2 4;
    6 0 3; 6 5 6; 6 3 0; 6 6 5;
    7 2 1; 7 7 4; 7 1 2; 7 4 7
]);

cfg.SECT = {
    [32 36; 36 40; 40 44; 44 48; 48 52; 52 56; 56 60; 60 64];
    [16 20; 20 24; 24 28; 28 32; 32 40; 40 48; 48 56; 56 64];
    [16 24; 24 32; 32 48; 48 64];
    [8 12; 12 16; 16 32; 32 64];
    [8 16; 16 64];
    [4 8; 8 64];
    [0 4; 4 64];
    [0 64]
};

gen_top('C:\LRMLD\decoders\ASYM_N64\top_64_L5_fsm3.sv', cfg);


