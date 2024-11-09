
% Thiago Rodrigo Monteiro Salgado 21954456

% Definindo str como uma disjunção anotada para múltiplos valores

0.95::str(dry); 0.2::str(wet); 0.1::str(snow_covered).

% Definindo probabilidades de outras variáveis independentes
0.4::flw.
0.98::b.
0.85::k.
0.7::v.

% Condicionais da variável r
0.03::r :- str(dry), flw.
0.01::r :- str(dry), \+flw.
0.4::r :- str(wet), flw.
0.06::r :- str(wet), \+flw.
0.98::r :- str(snow_covered), flw.
0.5::r :- str(snow_covered), \+flw.

% Condicionais para a variável Li
0.99::li :- v, b, k.
0.01::li :- v, b, \+k.
0.01::li :- v, \+b, k.
0.001::li :- v, \+b, \+k.
0.7::li :- \+v, b, k.
0.005::li :- \+v, b, \+k.
0.005::li :- \+v, \+b, k.
0.0::li :- \+v, \+b, \+k.

% Definindo queries e evidências
query(r).
query(li).

% Evidência
evidence(str(snow_covered), true).
