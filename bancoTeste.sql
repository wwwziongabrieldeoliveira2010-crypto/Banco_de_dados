-- =====================================================================
-- TRABALHO INTEGRADOR - BANCO DE DADOS I | OFICINA MECÂNICA
-- MySQL Workbench
-- =====================================================================
-- Estrutura do arquivo:
--  1. Criação do banco e tabelas (Parte 2)
--  2. Inserção de dados (Parte 3)
--  3. CRUD (Parte 4)
--  4. Consultas e filtros (Parte 5)
--  5. Funções de agregação (Parte 6)
--  6. GROUP BY e HAVING (Parte 7)
--  7. JOINs (Parte 8)
--  8. Subqueries (Parte 9)
--  9. Stored Procedures (Parte 10)
-- 10. Triggers (Parte 11)
-- 11. Integridade (Parte 12)
-- 12. Desafios (Partes 13 e 14)
-- 13. Roteiro de testes (Parte 15)
-- =====================================================================
-- DER (resumo textual):
--   clientes 1:N veiculos           (um cliente possui vários veículos)
--   veiculos 1:N ordens_servico     (um veículo pode ter várias ordens)
--   mecanicos 1:N ordens_servico    (um mecânico atende várias ordens)
--   ordens_servico 1:N itens_ordem  (uma ordem tem vários itens)
--   servicos 1:N itens_ordem        (um serviço aparece em vários itens)
--   servicos 1:N historico_precos   (histórico de alterações de preço)
-- ordens_servico <-> servicos é N:N, resolvido pela tabela itens_ordem.
-- =====================================================================


-- =====================================================================
-- PARTE 2 - CONSTRUÇÃO DO BANCO
-- =====================================================================
DROP DATABASE IF EXISTS oficina;
CREATE DATABASE oficina CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE oficina;

CREATE TABLE clientes (
    id_cliente     INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    cpf            CHAR(11)     NOT NULL UNIQUE,
    telefone       VARCHAR(20)  NOT NULL,
    email          VARCHAR(100),
    data_cadastro  DATE         NOT NULL DEFAULT (CURRENT_DATE)
);

CREATE TABLE veiculos (
    id_veiculo  INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente  INT          NOT NULL,
    placa       CHAR(7)      NOT NULL UNIQUE,
    marca       VARCHAR(50)  NOT NULL,
    modelo      VARCHAR(50)  NOT NULL,
    ano         SMALLINT     NOT NULL,
    cor         VARCHAR(30),
    CONSTRAINT fk_veiculo_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes (id_cliente),
    CONSTRAINT ck_veiculo_ano CHECK (ano BETWEEN 1950 AND 2100)
);

CREATE TABLE mecanicos (
    id_mecanico   INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    especialidade VARCHAR(50)  NOT NULL,
    telefone      VARCHAR(20),
    ativo         BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE servicos (
    id_servico    INT AUTO_INCREMENT PRIMARY KEY,
    descricao     VARCHAR(100)  NOT NULL UNIQUE,
    preco         DECIMAL(10,2) NOT NULL,
    tempo_estimado_min INT      NOT NULL DEFAULT 60,
    CONSTRAINT ck_servico_preco CHECK (preco > 0)
);

CREATE TABLE ordens_servico (
    id_ordem          INT AUTO_INCREMENT PRIMARY KEY,
    id_veiculo        INT      NOT NULL,
    id_mecanico       INT      NOT NULL,
    data_abertura     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_finalizacao  DATETIME NULL,
    status            ENUM('aberta','em_andamento','finalizada','cancelada')
                      NOT NULL DEFAULT 'aberta',
    observacoes       VARCHAR(255),
    CONSTRAINT fk_ordem_veiculo  FOREIGN KEY (id_veiculo)  REFERENCES veiculos (id_veiculo),
    CONSTRAINT fk_ordem_mecanico FOREIGN KEY (id_mecanico) REFERENCES mecanicos (id_mecanico)
);

CREATE TABLE itens_ordem (
    id_item        INT AUTO_INCREMENT PRIMARY KEY,
    id_ordem       INT           NOT NULL,
    id_servico     INT           NOT NULL,
    quantidade     INT           NOT NULL DEFAULT 1,
    valor_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,  -- preenchido pelo trigger 3
    CONSTRAINT fk_item_ordem   FOREIGN KEY (id_ordem)   REFERENCES ordens_servico (id_ordem),
    CONSTRAINT fk_item_servico FOREIGN KEY (id_servico) REFERENCES servicos (id_servico),
    CONSTRAINT ck_item_qtd CHECK (quantidade > 0)
);

-- Tabela de histórico (usada pelo Trigger 1)
CREATE TABLE historico_precos (
    id_historico   INT AUTO_INCREMENT PRIMARY KEY,
    id_servico     INT           NOT NULL,
    preco_anterior DECIMAL(10,2) NOT NULL,
    preco_novo     DECIMAL(10,2) NOT NULL,
    data_alteracao DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hist_servico FOREIGN KEY (id_servico) REFERENCES servicos (id_servico)
);


-- =====================================================================
-- PARTE 3 - ALIMENTAÇÃO DO BANCO
-- (Triggers e procedures são criados depois; aqui usamos INSERT direto)
-- =====================================================================
INSERT INTO clientes (nome, cpf, telefone, email) VALUES
('Maria Silva',      '11111111111', '48991110001', 'maria@email.com'),
('João Pereira',     '22222222222', '48991110002', 'joao@email.com'),
('Carlos Souza',     '33333333333', '48991110003', 'carlos@email.com'),
('Ana Oliveira',     '44444444444', '48991110004', 'ana@email.com'),
('Marcos Lima',      '55555555555', '48991110005', 'marcos@email.com'),
('Fernanda Costa',   '66666666666', '48991110006', 'fernanda@email.com'),
('Paulo Santos',     '77777777777', '48991110007', 'paulo@email.com'),
('Juliana Rocha',    '88888888888', '48991110008', 'juliana@email.com'),
('Ricardo Alves',    '99999999999', '48991110009', 'ricardo@email.com'),
('Beatriz Martins',  '10101010101', '48991110010', 'beatriz@email.com');

INSERT INTO veiculos (id_cliente, placa, marca, modelo, ano, cor) VALUES
(1,  'ABC1D23', 'Fiat',       'Uno',        2015, 'Branco'),
(1,  'BCD2E34', 'Honda',      'Civic',      2019, 'Preto'),
(2,  'CDE3F45', 'Volkswagen', 'Gol',        2014, 'Prata'),
(3,  'DEF4G56', 'Toyota',     'Corolla',    2020, 'Cinza'),
(4,  'EFG5H67', 'Chevrolet',  'Onix',       2018, 'Vermelho'),
(5,  'FGH6I78', 'Hyundai',    'HB20',       2017, 'Azul'),
(6,  'GHI7J89', 'Ford',       'Ka',         2016, 'Branco'),
(7,  'HIJ8K90', 'Renault',    'Kwid',       2021, 'Laranja'),
(8,  'IJK9L01', 'Jeep',       'Renegade',   2022, 'Preto'),
(9,  'JKL0M12', 'Fiat',       'Palio',      2012, 'Prata'),
(10, 'KLM1N23', 'Toyota',     'Hilux',      2023, 'Branco'),
(3,  'LMN2O34', 'Ford',       'Fiesta',     2013, 'Verde');

INSERT INTO mecanicos (nome, especialidade, telefone) VALUES
('Roberto Mendes',  'Motor',        '48992220001'),
('Sérgio Barros',   'Suspensão',    '48992220002'),
('Luciana Freitas', 'Elétrica',     '48992220003'),
('Anderson Reis',   'Freios',       '48992220004'),
('Tiago Ramos',     'Ar-condicionado', '48992220005');

INSERT INTO servicos (descricao, preco, tempo_estimado_min) VALUES
('Troca de óleo',                 150.00,  40),
('Alinhamento e balanceamento',   120.00,  60),
('Revisão completa',              650.00, 240),
('Troca de pastilhas de freio',   280.00,  90),
('Troca de bateria',              450.00,  30),
('Troca de correia dentada',      520.00, 180),
('Diagnóstico eletrônico',        100.00,  45),
('Troca de amortecedores',        890.00, 200),
('Higienização do ar-condicionado',180.00, 60),
('Troca de embreagem',           1200.00, 300);

INSERT INTO ordens_servico (id_veiculo, id_mecanico, data_abertura, data_finalizacao, status) VALUES
(1,  1, '2026-08-03 08:00:00', '2026-08-03 11:00:00', 'finalizada'),
(3,  2, '2026-08-05 09:00:00', '2026-08-05 14:00:00', 'finalizada'),
(4,  1, '2026-08-10 08:30:00', '2026-08-10 16:00:00', 'finalizada'),
(5,  3, '2026-09-20 10:00:00', NULL,                  'em_andamento'),
(6,  2, '2026-09-25 13:00:00', NULL,                  'aberta'),
(7,  4, '2026-08-18 09:00:00', '2026-08-18 12:00:00', 'finalizada'),
(9,  1, '2026-09-26 08:00:00', NULL,                  'aberta'),
(10, 5, '2026-08-22 15:00:00', NULL,                  'cancelada'),
(11, 3, '2026-09-01 08:00:00', '2026-09-01 17:00:00', 'finalizada'),
(2,  2, '2026-09-10 09:00:00', '2026-09-10 12:00:00', 'finalizada');

-- valor_unitario é omitido de propósito: o Trigger 3 copia o preço do serviço
-- (rodar a seção de Triggers ANTES desta inserção OU atualizar depois; ver nota abaixo)
-- Para não depender da ordem, informamos o valor explicitamente:
INSERT INTO itens_ordem (id_ordem, id_servico, quantidade, valor_unitario) VALUES
(1, 1,  1, 150.00),
(1, 2,  1, 120.00),
(2, 3,  1, 650.00),
(2, 1,  1, 150.00),
(3, 4,  1, 280.00),
(3, 5,  1, 450.00),
(4, 6,  1, 520.00),
(5, 7,  1, 100.00),
(5, 1,  1, 150.00),
(6, 8,  1, 890.00),
(7, 2,  1, 120.00),
(7, 9,  1, 180.00),
(8, 10, 1, 1200.00),
(9, 3,  1, 650.00),
(10, 1, 2, 150.00);


-- =====================================================================
-- PARTE 4 - CRUD
-- =====================================================================
-- CREATE (2 exemplos)
INSERT INTO clientes (nome, cpf, telefone, email)
VALUES ('Lucas Ferreira', '12312312312', '48991110011', 'lucas@email.com');
INSERT INTO mecanicos (nome, especialidade, telefone)
VALUES ('Vinícius Duarte', 'Injeção eletrônica', '48992220006');

-- READ (2 exemplos)
SELECT * FROM clientes;
SELECT placa, marca, modelo FROM veiculos WHERE ano >= 2018;

-- UPDATE (2 exemplos)
UPDATE clientes SET telefone = '48999999999' WHERE nome = 'Lucas Ferreira';
UPDATE servicos SET preco = 160.00 WHERE descricao = 'Troca de óleo';  -- dispara Trigger 1 (após criá-lo)

-- DELETE (2 exemplos)
DELETE FROM mecanicos WHERE nome = 'Vinícius Duarte';
DELETE FROM clientes  WHERE nome = 'Lucas Ferreira';


-- =====================================================================
-- PARTE 5 - CONSULTAS E FILTROS
-- =====================================================================
-- Listar clientes
SELECT * FROM clientes ORDER BY nome;

-- Veículos de um cliente
SELECT v.placa, v.marca, v.modelo
FROM veiculos v
WHERE v.id_cliente = 1;

-- Serviços acima de R$ 500
SELECT descricao, preco FROM servicos WHERE preco > 500 ORDER BY preco DESC;

-- Serviços entre R$ 100 e R$ 500
SELECT descricao, preco FROM servicos WHERE preco BETWEEN 100 AND 500;

-- Clientes por inicial do nome
SELECT nome FROM clientes WHERE nome LIKE 'M%';

-- Ordens abertas (aberta OU em andamento)
SELECT * FROM ordens_servico WHERE status IN ('aberta', 'em_andamento');

-- Cinco serviços mais caros
SELECT descricao, preco FROM servicos ORDER BY preco DESC LIMIT 5;

-- Exemplo com AND / OR
SELECT * FROM veiculos
WHERE (marca = 'Fiat' OR marca = 'Ford') AND ano < 2016;


-- =====================================================================
-- PARTE 6 - FUNÇÕES DE AGREGAÇÃO
-- =====================================================================
SELECT COUNT(*) AS total_clientes FROM clientes;
SELECT COUNT(*) AS total_veiculos FROM veiculos;
SELECT descricao, preco FROM servicos WHERE preco = (SELECT MAX(preco) FROM servicos);
SELECT descricao, preco FROM servicos WHERE preco = (SELECT MIN(preco) FROM servicos);
SELECT AVG(preco) AS preco_medio FROM servicos;
SELECT SUM(preco) AS valor_total_servicos FROM servicos;
-- Versão compacta com MIN/MAX:
SELECT MIN(preco) AS mais_barato, MAX(preco) AS mais_caro FROM servicos;


-- =====================================================================
-- PARTE 7 - GROUP BY E HAVING
-- =====================================================================
-- Quantidade de veículos por cliente
SELECT c.nome, COUNT(v.id_veiculo) AS qtd_veiculos
FROM clientes c
LEFT JOIN veiculos v ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome;

-- Quantidade de ordens atendidas por mecânico
SELECT m.nome, COUNT(o.id_ordem) AS qtd_ordens
FROM mecanicos m
JOIN ordens_servico o ON o.id_mecanico = m.id_mecanico
GROUP BY m.id_mecanico, m.nome;

-- Somente mecânicos com mais de uma ordem
SELECT m.nome, COUNT(o.id_ordem) AS qtd_ordens
FROM mecanicos m
JOIN ordens_servico o ON o.id_mecanico = m.id_mecanico
GROUP BY m.id_mecanico, m.nome
HAVING COUNT(o.id_ordem) > 1;


-- =====================================================================
-- PARTE 8 - JOINS
-- =====================================================================
-- Cliente + veículos
SELECT c.nome, v.placa, v.modelo
FROM clientes c
INNER JOIN veiculos v ON v.id_cliente = c.id_cliente;

-- Ordem + cliente + veículo
SELECT o.id_ordem, c.nome AS cliente, v.placa, o.status
FROM ordens_servico o
INNER JOIN veiculos v ON v.id_veiculo = o.id_veiculo
INNER JOIN clientes c ON c.id_cliente = v.id_cliente;

-- Ordem + mecânico
SELECT o.id_ordem, m.nome AS mecanico, o.status
FROM ordens_servico o
INNER JOIN mecanicos m ON m.id_mecanico = o.id_mecanico;

-- Ordem + serviços realizados
SELECT o.id_ordem, s.descricao, i.quantidade, i.valor_unitario
FROM ordens_servico o
INNER JOIN itens_ordem i ON i.id_ordem   = o.id_ordem
INNER JOIN servicos s    ON s.id_servico = i.id_servico;

-- Consulta completa: cliente, veículo, placa, mecânico, serviço, valor, data e status
SELECT c.nome AS cliente, v.modelo AS veiculo, v.placa,
       m.nome AS mecanico, s.descricao AS servico,
       i.quantidade * i.valor_unitario AS valor,
       o.data_abertura, o.status
FROM ordens_servico o
INNER JOIN veiculos v  ON v.id_veiculo  = o.id_veiculo
INNER JOIN clientes c  ON c.id_cliente  = v.id_cliente
INNER JOIN mecanicos m ON m.id_mecanico = o.id_mecanico
INNER JOIN itens_ordem i ON i.id_ordem  = o.id_ordem
INNER JOIN servicos s  ON s.id_servico  = i.id_servico
ORDER BY o.id_ordem;

-- LEFT JOIN: todos os clientes, mesmo os que nunca abriram ordem.
-- Motivo: o INNER JOIN descartaria clientes sem ordens (ex.: Paulo Santos).
-- Com LEFT JOIN eles aparecem com NULL, útil para campanhas de retorno.
SELECT c.nome, COUNT(o.id_ordem) AS qtd_ordens
FROM clientes c
LEFT JOIN veiculos v        ON v.id_cliente = c.id_cliente
LEFT JOIN ordens_servico o  ON o.id_veiculo = v.id_veiculo
GROUP BY c.id_cliente, c.nome
ORDER BY qtd_ordens;


-- =====================================================================
-- PARTE 9 - SUBQUERIES
-- =====================================================================
-- 1) Serviços com preço acima da média
--    Interna: calcula a média dos preços (1 valor).
--    Externa: compara o preço de cada serviço com esse valor.
SELECT descricao, preco
FROM servicos
WHERE preco > (SELECT AVG(preco) FROM servicos);

-- 2) Clientes que possuem ao menos uma ordem
--    Interna: lista os id_veiculo que aparecem em ordens.
--    Externa: seleciona clientes cujos veículos estão nessa lista.
SELECT nome FROM clientes
WHERE id_cliente IN (
    SELECT v.id_cliente FROM veiculos v
    WHERE v.id_veiculo IN (SELECT id_veiculo FROM ordens_servico)
);

-- 3) Serviços que nunca foram utilizados em nenhuma ordem
--    Interna: ids de serviços presentes em itens_ordem.
--    Externa: serviços cujo id NÃO está nessa lista.
SELECT descricao FROM servicos
WHERE id_servico NOT IN (SELECT DISTINCT id_servico FROM itens_ordem);


-- =====================================================================
-- PARTE 10 - STORED PROCEDURES
-- =====================================================================
DELIMITER $$

-- 1) Cadastrar cliente (com validação de CPF duplicado e nome vazio)
CREATE PROCEDURE cadastrar_cliente(
    IN p_nome VARCHAR(100), IN p_cpf CHAR(11),
    IN p_telefone VARCHAR(20), IN p_email VARCHAR(100))
BEGIN
    IF p_nome IS NULL OR TRIM(p_nome) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nome do cliente é obrigatório.';
    END IF;

    IF EXISTS (SELECT 1 FROM clientes WHERE cpf = p_cpf) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF já cadastrado.';
    END IF;

    INSERT INTO clientes (nome, cpf, telefone, email)
    VALUES (p_nome, p_cpf, p_telefone, p_email);
END$$

-- 2) Abrir ordem (valida veículo e mecânico ativo)
CREATE PROCEDURE abrir_ordem(
    IN p_id_veiculo INT, IN p_id_mecanico INT, IN p_obs VARCHAR(255))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM veiculos WHERE id_veiculo = p_id_veiculo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Veículo inexistente.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM mecanicos
                   WHERE id_mecanico = p_id_mecanico AND ativo = TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mecânico inexistente ou inativo.';
    END IF;

    INSERT INTO ordens_servico (id_veiculo, id_mecanico, observacoes)
    VALUES (p_id_veiculo, p_id_mecanico, p_obs);

    SELECT LAST_INSERT_ID() AS id_ordem_criada;
END$$

-- 3) Alterar status da ordem (valida status e regras de transição)
CREATE PROCEDURE alterar_status_ordem(IN p_id_ordem INT, IN p_novo_status VARCHAR(20))
BEGIN
    DECLARE v_status_atual VARCHAR(20);

    SELECT status INTO v_status_atual FROM ordens_servico WHERE id_ordem = p_id_ordem;

    IF v_status_atual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ordem inexistente.';
    ELSEIF p_novo_status NOT IN ('aberta','em_andamento','finalizada','cancelada') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Status inválido.';
    ELSEIF v_status_atual IN ('finalizada','cancelada') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ordem já encerrada não pode mudar de status.';
    ELSE
        UPDATE ordens_servico SET status = p_novo_status WHERE id_ordem = p_id_ordem;
    END IF;
END$$

-- 4) Escolhida pelo grupo: adicionar serviço a uma ordem
CREATE PROCEDURE adicionar_item_ordem(
    IN p_id_ordem INT, IN p_id_servico INT, IN p_quantidade INT)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status FROM ordens_servico WHERE id_ordem = p_id_ordem;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ordem inexistente.';
    ELSEIF v_status IN ('finalizada','cancelada') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível adicionar itens a ordem encerrada.';
    ELSEIF p_quantidade <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantidade deve ser maior que zero.';
    ELSE
        -- valor_unitario fica 0 e é preenchido pelo Trigger 3
        INSERT INTO itens_ordem (id_ordem, id_servico, quantidade)
        VALUES (p_id_ordem, p_id_servico, p_quantidade);
    END IF;
END$$

DELIMITER ;

-- Exemplos de chamada
CALL cadastrar_cliente('Lucas Ferreira', '12312312312', '48991110011', 'lucas@email.com');
CALL abrir_ordem(8, 4, 'Barulho ao frear');
CALL alterar_status_ordem(5, 'em_andamento');


-- =====================================================================
-- PARTE 11 - TRIGGERS
-- =====================================================================
DELIMITER $$

-- Trigger 1: registrar histórico ao alterar preço (usa OLD e NEW)
-- AFTER UPDATE: só grava o histórico depois que a alteração foi efetivada.
CREATE TRIGGER trg_historico_preco
AFTER UPDATE ON servicos
FOR EACH ROW
BEGIN
    IF OLD.preco <> NEW.preco THEN
        INSERT INTO historico_precos (id_servico, preco_anterior, preco_novo, data_alteracao)
        VALUES (OLD.id_servico, OLD.preco, NEW.preco, NOW());
    END IF;
END$$

-- Trigger 2: registrar data/hora de finalização
-- BEFORE UPDATE: precisamos alterar o próprio registro (NEW.data_finalizacao)
-- antes de ele ser gravado; em AFTER UPDATE isso não é permitido.
CREATE TRIGGER trg_data_finalizacao
BEFORE UPDATE ON ordens_servico
FOR EACH ROW
BEGIN
    IF NEW.status = 'finalizada' AND OLD.status <> 'finalizada' THEN
        SET NEW.data_finalizacao = NOW();
    END IF;
END$$

-- Trigger 3 (grupo): preencher automaticamente o valor unitário do item
-- Evento: INSERT em itens_ordem.
-- Necessidade: evita esquecimento e garante que o preço cobrado seja o
--              vigente no momento; o histórico da ordem não muda se o
--              preço do serviço mudar depois.
-- BEFORE: o valor precisa estar pronto antes de o registro ser gravado.
CREATE TRIGGER trg_valor_item
BEFORE INSERT ON itens_ordem
FOR EACH ROW
BEGIN
    IF NEW.valor_unitario IS NULL OR NEW.valor_unitario = 0 THEN
        SET NEW.valor_unitario = (SELECT preco FROM servicos WHERE id_servico = NEW.id_servico);
    END IF;
END$$

DELIMITER ;

-- Testes dos triggers
UPDATE servicos SET preco = 170.00 WHERE id_servico = 1;   -- Trigger 1
SELECT * FROM historico_precos;

CALL alterar_status_ordem(4, 'finalizada');                -- Trigger 2
SELECT id_ordem, status, data_finalizacao FROM ordens_servico WHERE id_ordem = 4;

CALL adicionar_item_ordem(5, 3, 1);                        -- Trigger 3
SELECT * FROM itens_ordem WHERE id_ordem = 5;


-- =====================================================================
-- PARTE 12 - INTEGRIDADE DO BANCO (executar uma por vez; todas devem falhar)
-- =====================================================================
-- 1) CPF duplicado                -> protegido por UNIQUE
-- INSERT INTO clientes (nome, cpf, telefone) VALUES ('Teste', '11111111111', '4800000000');

-- 2) Veículo para cliente inexistente -> protegido por FOREIGN KEY
-- INSERT INTO veiculos (id_cliente, placa, marca, modelo, ano) VALUES (999, 'ZZZ9Z99', 'Fiat', 'Uno', 2010);

-- 3) Preço inválido (negativo)    -> protegido por CHECK
-- INSERT INTO servicos (descricao, preco) VALUES ('Serviço inválido', -50);

-- 4) Exclusão de registro referenciado (cliente com veículos) -> FOREIGN KEY
-- DELETE FROM clientes WHERE id_cliente = 1;

-- 5) Ordem para veículo inexistente -> FOREIGN KEY (e Procedure abrir_ordem)
-- INSERT INTO ordens_servico (id_veiculo, id_mecanico) VALUES (999, 1);

-- 6) Campo obrigatório nulo       -> protegido por NOT NULL
-- INSERT INTO clientes (nome, cpf, telefone) VALUES (NULL, '12121212121', '4800000000');


-- =====================================================================
-- PARTE 13 - DESAFIO DE CONSULTA FINAL
-- Quanto cada cliente já gastou (apenas ordens finalizadas)
-- Recursos: JOINs, SUM, COUNT(DISTINCT), GROUP BY, LEFT JOIN, COALESCE, ORDER BY
-- =====================================================================
SELECT c.nome AS cliente,
       COUNT(DISTINCT o.id_ordem)                       AS qtd_ordens,
       COALESCE(SUM(i.quantidade * i.valor_unitario),0) AS total_gasto
FROM clientes c
LEFT JOIN veiculos v       ON v.id_cliente = c.id_cliente
LEFT JOIN ordens_servico o ON o.id_veiculo = v.id_veiculo AND o.status = 'finalizada'
LEFT JOIN itens_ordem i    ON i.id_ordem   = o.id_ordem
GROUP BY c.id_cliente, c.nome
ORDER BY total_gasto DESC;


-- =====================================================================
-- PARTE 14 - DESAFIO AVANÇADO
-- Mecânico que gerou o maior valor em serviços
-- Raciocínio: juntar mecânicos -> ordens -> itens, somar quantidade*valor,
-- agrupar por mecânico, ordenar decrescente e pegar o primeiro (LIMIT 1).
-- =====================================================================
SELECT m.nome AS mecanico,
       COUNT(DISTINCT o.id_ordem)                AS qtd_ordens,
       SUM(i.quantidade)                         AS qtd_servicos,
       SUM(i.quantidade * i.valor_unitario)      AS valor_total
FROM mecanicos m
JOIN ordens_servico o ON o.id_mecanico = m.id_mecanico
JOIN itens_ordem i    ON i.id_ordem    = o.id_ordem
GROUP BY m.id_mecanico, m.nome
ORDER BY valor_total DESC
LIMIT 1;


-- =====================================================================
-- PARTE 15 - ROTEIRO DE TESTES
-- Formato: operação | resultado esperado | resultado obtido (preencher ao testar)
-- =====================================================================
-- T1  SUCESSO: CALL cadastrar_cliente('Novo Cliente','20202020202','4899','n@e.com')
--     Esperado: cliente inserido.                      Obtido: ______
-- T2  ERRO:    CALL cadastrar_cliente('Outro','11111111111','4899','o@e.com')
--     Esperado: erro 'CPF já cadastrado.'              Obtido: ______
-- T3  SUCESSO: CALL abrir_ordem(1, 1, 'Revisão')
--     Esperado: nova ordem com status 'aberta'.        Obtido: ______
-- T4  ERRO:    CALL abrir_ordem(999, 1, 'x')
--     Esperado: erro 'Veículo inexistente.'            Obtido: ______
-- T5  SUCESSO: CALL alterar_status_ordem(5, 'em_andamento')
--     Esperado: status atualizado.                     Obtido: ______
-- T6  ERRO:    CALL alterar_status_ordem(1, 'aberta')
--     Esperado: erro 'Ordem já encerrada...'           Obtido: ______
-- T7  SUCESSO: UPDATE servicos SET preco = 200 WHERE id_servico = 2
--     Esperado: linha criada em historico_precos.      Obtido: ______
-- T8  SUCESSO: CALL alterar_status_ordem(7,'finalizada')
--     Esperado: data_finalizacao preenchida (trigger). Obtido: ______
-- T9  ERRO:    INSERT INTO servicos (descricao, preco) VALUES ('X', -10)
--     Esperado: violação de CHECK.                     Obtido: ______
-- T10 ERRO:    DELETE FROM clientes WHERE id_cliente = 1
--     Esperado: violação de FOREIGN KEY.               Obtido: ______
-- T11 SUCESSO: CALL adicionar_item_ordem(7, 4, 1)
--     Esperado: item criado com valor_unitario = preço do serviço. Obtido: ______
-- T12 ERRO:    CALL adicionar_item_ordem(1, 4, 1)
--     Esperado: erro 'Não é possível adicionar itens a ordem encerrada.' Obtido: ______
