# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Proteomics-MascotDB.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('AppConfig') };
BEGIN { use_ok('Carp') };
BEGIN { use_ok('DBI') };
BEGIN { use_ok('Proteomics::MascotDatabase') };

#########################

# create the db object
our $db = new Proteomics::MascotDatabase(name => 'mascot_test');
# TEST creation of the db is OK
ok(defined $db, 'mascot database connection creation...');
isa_ok($db, 'Proteomics::MascotDatabase', 'database connection reference is correct...');

# TEST check database structure
my $sh = $db->{_conn}->prepare("SHOW TABLES");
$sh->execute();
my @rows;
while (my $row_hashref = $sh->fetchrow_hashref()) {
  push @rows, $row_hashref;
}
is_deeply(\@rows,
          [{ 'Tables_in_mascot_test' => 'modification' },
           { 'Tables_in_mascot_test' => 'pep' },
           { 'Tables_in_mascot_test' => 'pep_has_modification' },
           { 'Tables_in_mascot_test' => 'prot' },
           { 'Tables_in_mascot_test' => 'prot_has_pep' },
           { 'Tables_in_mascot_test' => 'query' },
           { 'Tables_in_mascot_test' => 'query_has_pep' },
           { 'Tables_in_mascot_test' => 'search' }],
           'table structure of the database...');
## TODO 2011/03/23 JNS: check each table structured correctly

# TEST check mascot db can do all the things it is supposed to
can_ok($db, 'disconnect', 'get_modification', 'insert_search', 'insert_prot',
       'insert_pep', 'insert_modification', 'last_inserted_search_id', 
       'last_inserted_prot_id');

# TEST insert_search
my $search_id = $db->insert_search(searchtitle => 'Submitted from 20110125 JR by Mascot Daemon on BIOMOLSBEAST-PC',
  timestamp => '2011-01-25T12:46:48Z',
  user => 'Stacey Warwood',
  reporturi => 'http://msct/mascot/cgi/master_results.pl?file=../data/20110125/F291524534.dat',
  database => 'IPI_mouse');
$search_id = $db->insert_search(id => $search_id, significancethreshold => 0.05, maxnumberofhits => 0, usemudpitproteinscoring => 1, ionsscorecutoff => 0, includesamesetproteins => 0, includesubsetproteins => 0, includeunassigned => 0, requireboldred => 0);
print "search_id: $search_id\n";
## TODO 2011/03/25 ! JNS: check data added successfully

# TEST insert modifications
my @modifications = ();
$modifications[1] = $db->insert_modification(Identifier => 1, Name => "Oxidation (M)", Delta => 15.994919, "Neutral loss(es)" => 63.998285);
$modifications[2] = $db->insert_modification(Identifier => 2, Name => "Phospho (ST)", Delta => 79.966324, "Neutral loss(es)" => 97.976896);
$modifications[3] = $db->insert_modification(Identifier => 3, Name => "Phospho (Y)", Delta => 79.966324);


# TEST insert protein & peptide
my @protein_hit_headers = ('prot_hit_num', 'prot_acc', 'prot_desc', 'prot_score', 'prot_mass', 'prot_matches', 'prot_cover', 'prot_len', 'prot_pi', 'pep_query', 'pep_rank', 'pep_isbold', 'pep_exp_mz', 'pep_exp_mr', 'pep_exp_z', 'pep_calc_mr', 'pep_delta', 'pep_start', 'pep_end', 'pep_miss', 'pep_score', 'pep_expect', 'pep_res_before', 'pep_seq', 'pep_res_after', 'pep_var_mod', 'pep_var_mod_pos', 'pep_num_match', 'pep_scan_title');
my @protein_hit_line_eg = (1,"IPI00227299","Tax_Id=10090 Gene_Symbol=Vim Vimentin",4636,53712,414,62.4,466,5.06,327,1,1,351.2001,700.3856,2,700.3868,-0.0011,72,78,0,56.45,0.0012,"R","SSVPGVR","L","Phospho (ST)","0.2000000.0",6,"20110125_JR_AMF_FN_before.5239.5239.2.dta");
my @protein_hit_prot_args = ();
my @protein_hit_pep_args  = ();
for (my $ai = 0; $ai < @protein_hit_headers; $ai++) {
  if ($protein_hit_headers[$ai] =~ /^prot_/) {
    push @protein_hit_prot_args, $protein_hit_headers[$ai];
    push @protein_hit_prot_args, $protein_hit_line_eg[$ai];
  } elsif ($protein_hit_headers[$ai] =~ /^pep_/) {
    push @protein_hit_pep_args, $protein_hit_headers[$ai];
    push @protein_hit_pep_args, $protein_hit_line_eg[$ai];
  }
}
my $prot_id  = $db->insert_prot(@protein_hit_prot_args);
my $pep_id   = $db->insert_pep(@protein_hit_pep_args);
my $query_id = $db->last_inserted_query_id();
print "prot_id: $prot_id\npep_id: $pep_id\nquery_id: $query_id\n";

my @queries_headers = ("query_number","moverz","charge","intensity","StringTitle","Scan number range","Retention time range","TotalIonsIntensity","NumVals","StringIons1","StringIons2","StringIons3",'pep_rank','pep_isbold','pep_exp_mz','pep_exp_mr','pep_exp_z','pep_calc_mr','pep_delta','pep_start','pep_end','pep_miss','pep_score','pep_expect','pep_res_before','pep_seq','pep_res_after','pep_var_mod','pep_var_mod_pos','pep_num_match','pep_scan_title');
my $queries_line_eg = [
  [1,350.2494,"1+","","20110125_JR_AMF_FN_before.11578.11578.1.dta","","",174246.96,345,"195.044000:1674,293.142000:1.414e+04,333.180000:1.409e+04,123.125000:1471,291.143000:7115,307.023000:1.336e+04,181.089000:1220,253.153000:3332,323.017000:6141,179.118000:965.7,277.162000:2763,332.117000:5716,193.097000:796.1,289.155000:2732,305.148000:4276,163.073000:767.3,263.162000:2627,304.120000:3422,187.042000:710.4,279.124000:2543,308.999000:3353,153.111000:590.4,292.123000:1819,309.988000:3087,185.117000:559.3,251.069000:1793,306.029000:2575,165.138000:512.1,235.074000:1733,315.183000:2456,101.294000:32.01,102.100000:33.28,105.132000:127,107.018000:57.5,109.084000:299.8,110.102000:266.5,111.091000:89.58,113.011000:25.44,114.183000:29.01,115.087000:303.5,116.015000:131.1,117.220000:72.04,120.052000:204.6,121.106000:349.3,122.010000:111,125.116000:132.6,127.112000:262,129.087000:299.9,130.101000:54.66,131.133000:206.9,132.059000:55.86,133.146000:122.5,135.051000:91.45,136.146000:31.78,137.063000:155.7,139.052000:126.6,140.049000:69.03,141.136000:101,142.024000:39.02,142.738000:95.62,143.145000:315.7,145.041000:124.4,145.978000:15.16,147.147000:296.3,149.142000:256.3,151.090000:502.2,151.955000:34.1,155.092000:137.6,156.048000:100.8,157.008000:128.4,158.091000:111.2,159.083000:175.7,161.153000:190.7,163.953000:239.4,166.097000:156.4,167.160000:176.6,169.089000:327.4,170.192000:62.33,171.043000:484.5,172.060000:117.4,173.098000:203.6,175.027000:197.5,176.003000:66.13,176.418000:33.49,177.081000:343.7,178.133000:166.7,180.030000:209,182.171000:51.72,183.112000:404.2,184.019000:374.2,184.429000:46.54,186.184000:106.8,187.993000:27.45,189.104000:107.2,190.230000:25.4,191.077000:451.6,192.135000:147.9,197.130000:390.4,198.242000:45.57,199.106000:175.7,200.092000:116.9,201.080000:97.36,202.036000:175.4,203.074000:369.2,204.198000:173,205.171000:410.6,206.084000:181.6,207.140000:732.7,208.055000:61.79,209.106000:600.8,210.066000:167.6,211.074000:1203,212.078000:129.9,213.167000:506.9,214.263000:157.1,215.151000:509.9,216.108000:69.78,217.147000:87.31,218.043000:31.28,219.114000:793.6,220.204000:212.6,221.113000:1145,222.084000:125.7,223.118000:910.7,224.089000:257.5,225.109000:371.9,225.934000:171.1,227.127000:91.52,228.228000:198.4,229.028000:600.9,229.380000:30.93,230.233000:94.61,231.072000:162.8,233.153000:1002,233.675000:45.96,234.177000:182.5,236.114000:196.3,237.140000:1524,238.020000:399.1,239.068000:564.8,241.102000:164.6,242.214000:23.16,243.149000:359.9,243.642000:83.07,244.129000:97.71,245.218000:75.46,246.273000:94.26,247.117000:665.7,248.071000:414.9,249.158000:1297,250.103000:151.2,252.059000:391.8,253.917000:121.3,254.233000:255.5,255.092000:408.9,256.083000:28.26,257.115000:227.8,257.603000:87.66,258.191000:38.71,259.119000:323.9,260.089000:245.2,261.145000:968.2,262.141000:343.2,264.114000:432.9,265.163000:808.3,265.836000:59.71,266.139000:106.5,267.074000:679,268.138000:445.8,269.124000:527.2,269.449000:56.33,270.147000:178.3,271.087000:269.6,272.191000:213.9,273.062000:385.5,274.080000:104.6,275.168000:753.2,276.064000:699.1,277.735000:112.9,278.127000:424.4,280.213000:33.83,281.174000:388.8,282.112000:183.7,283.068000:113.1,283.409000:89.77,285.145000:173.8,286.024000:98.26,287.154000:956.3,288.193000:573.6,289.642000:170.9,290.178000:839.5,291.699000:344.9,293.578000:33.85,294.154000:596.2,295.107000:364.2,295.527000:155.3,296.104000:223.1,297.162000:255.4,299.036000:37.98,300.009000:149.7,300.995000:85.21,302.078000:133.3,303.166000:486.3,304.430000:315.8,306.474000:80.85,307.666000:68.25,308.047000:619.3,309.437000:179.9,311.266000:209.6,312.021000:80.67,313.153000:179.4,314.197000:184.4,315.723000:63.34,318.841000:79.78,319.405000:71.16,320.025000:211.8,321.102000:673.9,322.051000:1286,323.369000:190.7,325.023000:430.1,326.086000:29.5,326.797000:28.86,327.106000:336.6,328.075000:344,329.396000:35.25,330.034000:186.7,330.557000:213.2,331.212000:891.9,332.583000:332.4,334.247000:105,335.095000:46.09,335.714000:19.28,336.299000:107.7,337.107000:47.11,340.978000:761.5,341.528000:72.13,342.188000:101.1,345.169000:38.55,349.229000:1742,356.241000:92.29,357.108000:25.27,361.069000:78.36,363.140000:21.79,364.105000:132.5,367.144000:29.77,368.134000:42.8,369.024000:70.26,370.192000:133.1,375.046000:19.82,376.162000:19.32,379.081000:49.3,381.022000:177.3,382.198000:110.1,384.259000:19.04,385.121000:136.6,388.288000:39.29,391.970000:25.92,398.174000:29.21,402.163000:106.7,403.306000:73.72,405.226000:288.1,407.149000:89.17,410.598000:34.03,411.207000:165.5,413.119000:43.88,414.180000:25.22,416.278000:115.5,417.044000:212.3,418.368000:92.34,419.136000:296.8,420.260000:64.79,421.192000:95.49,423.226000:179.2,424.293000:38.77,426.260000:213.2,428.142000:154.6,429.042000:105,431.059000:57.62,431.439000:121.8,433.676000:165.8,435.133000:53.1,438.270000:17.2,439.204000:167.2,440.284000:101,445.907000:57.97,447.200000:17.29,447.970000:30.22,450.236000:78.23,451.280000:528.6,451.793000:47.98,453.207000:145,455.096000:21.76,457.272000:41.37,459.095000:43.02,461.349000:51.2,461.705000:72.91,466.163000:42.71,466.822000:41.84,467.338000:42.82,471.143000:47.03,473.055000:153.5,473.992000:106.9,482.650000:19.33,483.113000:31.75,484.324000:160.2,486.213000:76.96,486.866000:187.5,488.197000:123.1,489.706000:23.55,495.308000:17.85,496.075000:37.49,504.273000:86.23,505.205000:89.88,512.941000:110.8,514.253000:205.5,514.840000:53.55,515.298000:83.6,526.149000:47.37,531.178000:40.19,535.289000:87.95,541.085000:155.7,542.849000:27.4,544.140000:113.7,544.814000:86.61,545.118000:83.83,551.264000:141.3,551.673000:215.8,552.225000:99.72,556.025000:19.08,559.203000:27.83,563.186000:27.39,564.239000:339.1,569.352000:76.24,570.343000:164.5,572.821000:57.98,584.006000:41.82,586.382000:27.81,587.343000:92.04,600.120000:130.3,603.127000:53.68,610.104000:45.2,612.206000:67.69,616.373000:23.1,616.914000:19.71,663.153000:43.75","",""],
  [327,351.2001,"2+","","20110125_JR_AMF_FN_before.5239.5239.2.dta","","",17043181.4,200,"175.116000:5.517e+05,256.167000:3.63e+06,342.271000:2.645e+05,428.248000:7.054e+06,527.258000:1.021e+06,614.329000:1.314e+04,147.150000:1.475e+05,274.174000:1.607e+06,331.259000:8.364e+04,429.252000:9.635e+05,528.267000:1.758e+05,615.354000:5697,129.114000:7.011e+04,257.190000:2.576e+05,342.737000:8.13e+04,429.586000:1.844e+04,533.240000:1.557e+04,625.341000:5014,176.149000:2.048e+04,275.189000:1.428e+05,371.262000:5.093e+04,412.315000:9036,526.238000:7308,624.373000:2141,168.178000:9702,264.278000:1.315e+05,386.265000:2.004e+04,411.235000:8949,509.233000:6708,603.474000:1023,157.150000:6973,211.207000:7.591e+04,332.324000:1.557e+04,456.219000:5519,596.302000:5150,682.319000:652.9,102.151000:5830,246.226000:4.915e+04,323.266000:7364,474.117000:4581,543.270000:3244,130.147000:4927,214.731000:4.572e+04,315.270000:5470,402.279000:4077,510.269000:3235,140.132000:4762,229.154000:4.005e+04,343.219000:4916,476.271000:3869,591.342000:2782,148.063000:4573,274.540000:3.494e+04,316.208000:4882,491.334000:3444,515.230000:2128,105.766000:617.4,112.223000:472.9,114.158000:437.4,115.227000:477.2,116.130000:2694,120.157000:3398,127.091000:1528,129.422000:1674,136.094000:801.5,141.232000:772.8,149.299000:655.6,155.096000:1926,158.153000:2935,169.334000:3140,170.259000:431.1,171.299000:588.7,173.107000:558.1,175.553000:1357,177.174000:365.1,183.195000:944.1,184.237000:2367,185.142000:4556,186.293000:586.9,187.196000:3566,194.198000:943.3,195.141000:2208,197.245000:1809,199.252000:3582,201.231000:729,212.225000:1.104e+04,213.080000:1639,214.280000:799.6,215.236000:1.491e+04,224.268000:434.3,225.285000:1020,226.252000:1742,227.289000:1379,227.933000:8767,228.242000:1.793e+04,229.492000:533.6,230.233000:2497,231.246000:976.5,236.301000:2790,237.060000:1626,238.175000:1678,242.503000:1055,243.303000:1239,244.279000:3175,245.312000:1179,247.282000:5053,254.276000:7170,256.680000:2584,259.986000:1600,264.748000:1.997e+04,265.180000:740.6,268.042000:1014,268.449000:1054,272.172000:1237,275.829000:1343,280.296000:1186,282.189000:618.9,288.327000:1952,289.259000:3342,290.225000:1566,291.101000:6143,291.852000:5940,295.719000:2487,299.423000:975.9,300.369000:4256,304.202000:1741,304.939000:581.3,307.096000:1079,307.712000:789.2,310.345000:875.4,311.157000:800.7,312.228000:3899,320.260000:919.8,321.220000:1727,322.163000:979.7,324.006000:3184,324.505000:858.7,325.336000:3908,326.269000:887,327.857000:3972,333.182000:4458,334.257000:2377,335.262000:1235,336.286000:1017,341.800000:1735,348.143000:628.2,353.298000:721.8,353.969000:504.8,354.288000:2209,356.178000:1014,359.274000:1930,360.228000:4771,363.257000:2820,369.283000:1524,372.195000:4039,375.363000:583.1,381.306000:469.7,387.252000:4846,391.479000:1227,392.320000:2117,395.209000:2703,400.305000:1343,403.255000:2126,406.453000:1190,414.291000:1783,426.317000:364.5,429.936000:2333,434.068000:1581,445.284000:1055,452.222000:3127,457.260000:2944,458.096000:2671,458.400000:1441,461.230000:983.2,467.179000:1159,470.268000:1015,471.259000:2158,473.224000:1719,474.532000:427.6,475.224000:832.9,480.080000:436.1,486.263000:467.9,490.315000:2622,492.279000:1456,503.311000:764.9,507.153000:977.1,508.249000:1310,511.179000:1149,514.252000:1137,516.222000:1740,517.182000:1119,518.185000:1229,528.666000:1789,530.370000:840.6,535.271000:1498,539.248000:1562,544.316000:1490,555.319000:468.8,587.374000:1838,601.301000:1292","","",1,"",351.2001,700.3856,2,700.3868,-0.0011,"","",0,56.45,0.0012,"","SSVPGVR","","","",6,"20110125_JR_AMF_FN_before.5239.5239.2.dta",""],
  [343,"","","","","","","","","","","",2,"",351.2787,700.5428,2,700.3980,0.1448,"","",1,1.95,3.3e+02,"","AVRGGGGK","","","",4,"20110125_JR_AMF_FN_before.7594.7594.2.dta",]
];
my @queries_args1 = ();
my @queries_args2 = ();
my @queries_args3 = ();
for (my $ai = 0; $ai < @queries_headers; $ai++) {
  push @queries_args1, $queries_headers[$ai];
  push @queries_args2, $queries_headers[$ai];
  push @queries_args3, $queries_headers[$ai];
  push @queries_args1, (defined $queries_line_eg->[0]->[$ai] && $queries_line_eg->[0]->[$ai] ne "") ? $queries_line_eg->[0]->[$ai] : "";
  push @queries_args2, (defined $queries_line_eg->[1]->[$ai] && $queries_line_eg->[1]->[$ai] ne "") ? $queries_line_eg->[1]->[$ai] : "";
  push @queries_args3, (defined $queries_line_eg->[2]->[$ai] && $queries_line_eg->[2]->[$ai] ne "") ? $queries_line_eg->[2]->[$ai] : "";
}
$query_id  = $db->insert_query(@queries_args1);
print "inserted query (id): $query_id\n";
$query_id  = $db->insert_query(@queries_args2);
print "inserted query (id): $query_id\n";
$query_id  = $db->insert_query(@queries_args3);
print "inserted query (id): $query_id\n";

## TODO 2011/03/23 JNS: whether to add data and how to retreive to check it
