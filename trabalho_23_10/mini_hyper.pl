%---------------------------------------------------------
% Exemplos positivos (ex/1)
ex(predecessor(pam, bob)).
ex(predecessor(pam, jim)).
ex(predecessor(tom, ann)).
ex(predecessor(tom, liz)).

% Exemplos negativos (nex/1)
nex(predecessor(liz, bob)).
nex(predecessor(pat, bob)).
nex(predecessor(pam, liz)).
nex(predecessor(liz, jim)).

%---------------------------------------------------------
% Predicados de fundo
prolog_predicate(parent/2).

% Definições do predicado parent/2
parent(pam, ann).
parent(ann, jim).
parent(tom, liz).
parent(tom, ann).
parent(pam, bob).
parent(bob, jim).

%---------------------------------------------------------
% Hipótese inicial - Começando com uma hipótese mais simples
start_hyp([ [predecessor(X, Y)] / [X, Y] ]).

%---------------------------------------------------------
% Definir backliteral/2 para permitir o uso de predicados de fundo
backliteral(parent(X, Y), [X, Y]).

%---------------------------------------------------------
% Código para indução

prove(Goal, Hypo, Answer):-
    max_proof_length(D),
    prove(Goal, Hypo, D, RestD),
    (RestD >= 0, Answer = yes        % Proved
     ;                 
     RestD < 0, Answer = maybe).    % Maybe, but it looks like inf. loop
prove(Goal, _, no).                 % Otherwise goal definitely cannot be proved

prove(G, H, D, D):- 
    D < 0, !.
prove([], _, D, D):- !.
prove([G1|Gs], Hypo, D0, D):- 
    prove(G1, Hypo, D0, D1), 
    prove(Gs, Hypo, D1, D).
prove(G, _, D, D):- 
    prolog_predicate(G), 
    call(G).
prove(G, Hypo, D0, D):- 
    D0 =< 0, !, 
    D is D0-1 
    ; 
    D1 is D0 - 1, 
    member(Clause/Vars, Hypo), 
    copy_term(Clause, [Head|Body]), 
    G = Head, 
    prove(Body, Hypo, D1, D).

induce(Hyp):- 
    iter_deep(Hyp, 0).

iter_deep(Hyp, MaxD):- 
    MaxD > 24, !,                % Limite máximo de profundidade
    write('Limite de profundidade atingido'), nl, 
    fail.
iter_deep(Hyp, MaxD):- 
    write('MaxD= '), write(MaxD), nl,
    start_hyp(Hyp0),
    complete(Hyp0),
    depth_first(Hyp0, Hyp, MaxD), 
    !;                          % Parar se encontrar uma hipótese consistente
    NewMaxD is MaxD + 1, 
    iter_deep(Hyp, NewMaxD).

depth_first(Hyp, Hyp, _):- 
    consistent(Hyp).
depth_first(Hyp0, Hyp, MaxD0):- 
    MaxD0 > 0, 
    MaxD1 is MaxD0 - 1, 
    refine_hyp(Hyp0, Hyp1), 
    complete(Hyp1), 
    write('Hipótese refinada: '), write(Hyp1), nl, % Depuração
    depth_first(Hyp1, Hyp, MaxD1).

complete(Hyp):- 
    not(ex(E),                % Verificar se todos os exemplos positivos são cobertos
        once(prove(E, Hyp, Answer)), % Tentar provar com a hipótese
        Answer \== yes).      % Se não puder ser provado, a hipótese não está completa

consistent(Hyp):- 
    not(nex(E),               % Verificar se nenhum exemplo negativo é coberto
        once(prove(E, Hyp, Answer)), % Tentar provar com a hipótese
        Answer \== no).       % Se puder ser provado, a hipótese não é consistente

refine_hyp(Hyp0, Hyp):- 
    conc(Clauses1, [Clause0/Vars0 | Clauses2], Hyp0), 
    conc(Clauses1, [Clause/Vars | Clauses2], Hyp), 
    refine(Clause0, Vars0, Clause, Vars).

refine(Clause, Args, Clause, NewArgs):- 
    conc(Args1, [A | Args2], Args), 
    member(A, Args2), 
    conc(Args1, Args2, NewArgs).
refine(Clause, Args, NewClause, NewArgs):- 
    length(Clause, L), 
    max_clause_length(MaxL), 
    L < MaxL, 
    backliteral(Lit, Vars), 
    conc(Clause, [Lit], NewClause), 
    conc(Args, Vars, NewArgs).

max_proof_length(10).
max_clause_length(3).

conc([], L, L).
conc([X | T], L, [X | L1]):- 
    conc(T, L, L1).

not(A, B, C):- 
    A, 
    B, 
    C, !, fail.
not(_, _, _).
