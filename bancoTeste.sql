-- =====================================================================
-- RELATÓRIO DO TRABALHO INTEGRADOR - BANCO DE DADOS I | OFICINA MECÂNICA
-- Curso: Ensino Médio com Técnico Integrado (EMETEC)
-- Ferramenta: MySQL Workbench
-- =====================================================================
-- Nome(s): __________________________________________________________________
-- Turma: _________________________ Data: _________________________
--
-- Dificuldades Encontradas: 
-- [Espaço reservado para o grupo descrever brevemente as dificuldades 
--  enfrentadas durante o desenvolvimento, conforme exigido no item 18 do PDF]
-- =====================================================================

-- =====================================================================
-- PARTE 1 - ANÁLISE E MODELAGEM
-- =====================================================================
-- REPRESENTAÇÃO TEXTUAL DO DER (Diagrama Entidade-Relacionamento):
-- 1. CLIENTES (1) ----< (N) VEICULOS
-- 2. CLIENTES (1) ----< (N) ORDENS_SERVICO (via Veículos)
-- 3. MECANICOS (1) ----< (N) ORDENS_SERVICO
-- 4. ORDENS_SERVICO (1) ----< (N) ITENS_ORDEM
-- 5. SERVICOS (1) ----< (N) ITENS_ORDEM
-- 6. SERVICOS (1) ----< (N) HISTORICO_PRECOS
--
-- Explicação do Relacionamento 1:N (Clientes e Veículos):
-- Existe um relacionamento 1:N (Um-para-Muitos) entre 'clientes' e 'veiculos'. 
-- Um cliente pode possuir vários veículos cadastrados na oficina, mas 
-- cada veículo pertence a apenas um cliente. A chave primária (id_cliente) 
-- migra para a tabela 'veiculos' como chave estrangeira (FOREIGN KEY).
--
-- OBSERVAÇÃO PARA ENTREGA: Gere o DER visual no MySQL Workbench indo em:
-- Database > Forward Engineer > (Avançar até gerar o diagrama) e salve a imagem.
-- =====================================================================

-- =====================================================================
-- PARTE 2 - CONSTRUÇÃO DO BANCO
-- =====================================================================
DROP DATABASE IF EXISTS oficina;
CREATE DATABASE oficina CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE oficina;

CREATE TABLE clientes (
    id_cliente    INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    cpf           CHAR(11)     NOT NULL UNIQUE,
    telefone      VARCHAR(20)  NOT NULL,
    email         VARCHAR(100),
    data_cadastro DATE         NOT NULL DEFAULT (CURRENT_DATE)
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
    id_servico         INT AUTO_INCREMENT PRIMARY KEY,
    descricao          VARCHAR(100)  NOT NULL UNIQUE,
    preco              DECIMAL(10,2) NOT NULL,
    tempo_estimado_min INT           NOT NULL DEFAULT 60,
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
    id_ordem       INT            NOT NULL,
    id_servico     INT            NOT NULL,
    quantidade     INT            NOT NULL DEFAULT 1,
    valor_unitario DECIMAL(10,2)  NOT NULL DEFAULT 0,
    CONSTRAINT fk_item_ordem   FOREIGN KEY (id_ordem)   REFERENCES ordens_servico (id_ordem),
    CONSTRAINT fk_item_servico FOREIGN KEY (id_servico) REFERENCES servicos (id_servico),
    CONSTRAINT ck_item_qtd CHECK (quantidade > 0)
);

CREATE TABLE historico_precos (
    id_historico   INT AUTO_INCREMENT PRIMARY KEY,
    id_servico     INT            NOT NULL,
    preco_anterior DECIMAL(10,2)  NOT NULL,
    preco_novo     DECIMAL(10,2)  NOT NULL,
    data_alteracao DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hist_servico FOREIGN KEY (id_servico) REFERENCES servicos (id_servico)
);

-- =====================================================================
-- PARTE 10 - STORED PROCEDURES
-- =====================================================================
DELIMITER $$

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

CREATE PROCEDURE abrir_ordem(
    IN p_id_veiculo INT, IN p_id_mecanico INT, IN p_obs VARCHAR(255))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM veiculos WHERE id_veiculo = p_id_veiculo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Veículo inexistente.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM mecanicos WHERE id_mecanico = p_id_mecanico AND ativo = TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mecânico inexistente ou inativo.';
    END IF;

    INSERT INTO ordens_servico (id_veiculo, id_mecanico, observacoes)
    VALUES (p_id_veiculo, p_id_mecanico, p_obs);

    SELECT LAST_INSERT_ID() AS id_ordem_criada;
END$$

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
        INSERT INTO itens_ordem (id_ordem, id_servico, quantidade)
        VALUES (p_id_ordem, p_id_servico, p_quantidade);
    END IF;
END$$

DELIMITER ;

-- =====================================================================
-- PARTE 11 - TRIGGERS 
-- =====================================================================
-- Explicações exigidas:
-- Trigger 2 (trg_data_finalizacao): Usado BEFORE UPDATE pois precisamos
-- interceptar o dado antes de ser salvo no banco para alterar a coluna 
-- data_finalizacao na mesma linha que está sendo atualizada.
-- Trigger 3 (trg_valor_item): Evento: BEFORE INSERT. Necessidade: Garantir 
-- que o valor unitário do item seja registrado corretamente no momento da 
-- criação, mesmo que o preço do serviço mude no futuro. Escolha BEFORE: 
-- Para modificar o valor da coluna NEW.valor_unitario antes que a linha 
-- seja efetivamente gravada no banco.
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_historico_preco
AFTER UPDATE ON servicos
FOR EACH ROW
BEGIN
    IF OLD.preco <> NEW.preco THEN
        INSERT INTO historico_precos (id_servico, preco_anterior, preco_novo, data_alteracao)
        VALUES (OLD.id_servico, OLD.preco, NEW.preco, NOW());
    END IF;
END$$

CREATE TRIGGER trg_data_finalizacao
BEFORE UPDATE ON ordens_servico
FOR EACH ROW
BEGIN
    IF NEW.status = 'finalizada' AND OLD.status <> 'finalizada' THEN
        SET NEW.data_finalizacao = NOW();
    END IF;
END$$

CREATE TRIGGER trg_valor_item
BEFORE INSERT ON itens_ordem
FOR EACH ROW
BEGIN
    IF NEW.valor_unitario IS NULL OR NEW.valor_unitario = 0 THEN
        SET NEW.valor_unitario = (SELECT preco FROM servicos WHERE id_servico = NEW.id_servico);
    END IF;
END$$

DELIMITER ;

-- =====================================================================
-- PARTE 3 - ALIMENTAÇÃO DO BANCO (Dados coerentes e relacionados)
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
('Roberto Mendes',  'Motor',           '48992220001'),
('Sérgio Barros',   'Suspensão',       '48992220002'),
('Luciana Freitas', 'Elétrica',        '48992220003'),
('Anderson Reis',   'Freios',          '48992220004'),
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

INSERT INTO itens_ordem (id_ordem, id_servico, quantidade) VALUES
(1, 1, 1), (1, 2, 1), (2, 3, 1), (2, 1, 1), (3, 4, 1),
(3, 5, 1), (4, 6, 1), (5, 7, 1), (5, 1, 1), (6, 8, 1),
(7, 2, 1), (7, 9, 1), (8, 10, 1), (9, 3, 1), (10, 1, 2);

-- =====================================================================
-- PARTE 4 - CRUD (2 exemplos de cada)
-- =====================================================================
-- CREATE
INSERT INTO clientes (nome, cpf, telefone, email) VALUES ('Lucas Ferreira', '12312312312', '48991110011', 'lucas@email.com');
INSERT INTO mecanicos (nome, especialidade, telefone) VALUES ('Vinícius Duarte', 'Injeção eletrônica', '48992220006');

-- READ
SELECT * FROM clientes;
SELECT placa, marca, modelo FROM veiculos WHERE ano >= 2018;

-- UPDATE
UPDATE clientes SET telefone = '48999999999' WHERE nome = 'Lucas Ferreira';
UPDATE servicos SET preco = 160.00 WHERE descricao = 'Troca de óleo'; 

-- DELETE (Exemplos funcionais. Nota: excluímos propositalmente os registros criados 
-- nesta seção para não afetar os relatórios das Partes 13 e 14)
DELETE FROM mecanicos WHERE nome = 'Vinícius Duarte';
DELETE FROM clientes  WHERE nome = 'Lucas Ferreira';

-- =====================================================================
-- PARTE 5 - CONSULTAS E FILTROS
-- =====================================================================
SELECT * FROM clientes ORDER BY nome; -- Listar clientes
SELECT v.placa, v.marca, v.modelo FROM veiculos v WHERE v.id_cliente = 1; -- Veículos de um cliente
SELECT descricao, preco FROM servicos WHERE preco > 500 ORDER BY preco DESC; -- Serviços > R$ 500
SELECT descricao, preco FROM servicos WHERE preco BETWEEN 100 AND 500; -- Serviços entre R$ 100 e R$ 500
SELECT nome FROM clientes WHERE nome LIKE 'M%'; -- Clientes por inicial do nome
SELECT * FROM ordens_servico WHERE status = 'aberta'; -- Ordens abertas
SELECT * FROM servicos WHERE id_servico IN (1, 3, 5); -- Exemplo explícito do uso do operador IN
SELECT descricao, preco FROM servicos ORDER BY preco DESC LIMIT 5; -- 5 serviços mais caros
SELECT * FROM veiculos WHERE (marca = 'Fiat' OR marca = 'Ford') AND ano < 2016; -- Uso de AND/OR

-- =====================================================================
-- PARTE 6 - FUNÇÕES DE AGREGAÇÃO
-- =====================================================================
SELECT COUNT(*) AS total_clientes FROM clientes;
SELECT COUNT(*) AS total_veiculos FROM veiculos;
-- Serviço mais caro (Utilizando a função MAX() conforme exigido no enunciado)
SELECT descricao, preco FROM servicos WHERE preco = (SELECT MAX(preco) FROM servicos); 
-- Serviço mais barato (Utilizando a função MIN() conforme exigido no enunciado)
SELECT descricao, preco FROM servicos WHERE preco = (SELECT MIN(preco) FROM servicos); 
SELECT AVG(preco) AS preco_medio FROM servicos;
SELECT SUM(preco) AS valor_total_servicos FROM servicos;

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

-- Mecânicos com mais de uma ordem
SELECT m.nome, COUNT(o.id_ordem) AS qtd_ordens
FROM mecanicos m
JOIN ordens_servico o ON o.id_mecanico = m.id_mecanico
GROUP BY m.id_mecanico, m.nome
HAVING COUNT(o.id_ordem) > 1;

-- =====================================================================
-- PARTE 8 - JOINS
-- =====================================================================
-- Cliente + Veículos
SELECT c.nome, v.placa, v.modelo FROM clientes c INNER JOIN veiculos v ON v.id_cliente = c.id_cliente;

-- Ordem + Cliente + Veículo
SELECT o.id_ordem, c.nome AS cliente, v.placa, o.status
FROM ordens_servico o
INNER JOIN veiculos v ON v.id_veiculo = o.id_veiculo
INNER JOIN clientes c ON c.id_cliente = v.id_cliente;

-- Ordem + Mecânico
SELECT o.id_ordem, m.nome AS mecanico, o.status
FROM ordens_servico o INNER JOIN mecanicos m ON m.id_mecanico = o.id_mecanico;

-- Ordem + Serviços realizados
SELECT o.id_ordem, s.descricao, i.quantidade, i.valor_unitario
FROM ordens_servico o
INNER JOIN itens_ordem i ON i.id_ordem = o.id_ordem
INNER JOIN servicos s ON s.id_servico = i.id_servico;

-- Consulta Completa
SELECT c.nome AS cliente, v.modelo AS veiculo, v.placa, m.nome AS mecanico, 
       s.descricao AS servico, (i.quantidade * i.valor_unitario) AS valor, 
       o.data_abertura, o.status
FROM ordens_servico o
INNER JOIN veiculos v ON v.id_veiculo = o.id_veiculo
INNER JOIN clientes c ON c.id_cliente = v.id_cliente
INNER JOIN mecanicos m ON m.id_mecanico = o.id_mecanico
INNER JOIN itens_ordem i ON i.id_ordem = o.id_ordem
INNER JOIN servicos s ON s.id_servico = i.id_servico
ORDER BY o.id_ordem;

-- LEFT JOIN (Explicação: Usado para garantir que TODOS os clientes apareçam, 
-- mesmo os que não têm veículos ou ordens. O INNER JOIN ocultaria esses clientes).
SELECT c.nome, COUNT(o.id_ordem) AS qtd_ordens
FROM clientes c
LEFT JOIN veiculos v ON v.id_cliente = c.id_cliente
LEFT JOIN ordens_servico o ON o.id_veiculo = v.id_veiculo
GROUP BY c.id_cliente, c.nome
ORDER BY qtd_ordens;

-- =====================================================================
-- PARTE 9 - SUBQUERIES
-- =====================================================================
-- 1) Serviços com preço acima da média
-- Interna: Calcula a média geral de preços. Externa: Filtra serviços acima desse valor.
SELECT descricao, preco FROM servicos WHERE preco > (SELECT AVG(preco) FROM servicos);

-- 2) Clientes com ao menos uma ordem registrada
-- Interna: Busca IDs de veículos em ordens. Intermediária: IDs de clientes desses veículos. Externa: Nomes dos clientes.
SELECT nome FROM clientes WHERE id_cliente IN (
    SELECT v.id_cliente FROM veiculos v WHERE v.id_veiculo IN (SELECT id_veiculo FROM ordens_servico)
);

-- 3) Serviços que nunca foram utilizados em ordens
-- Interna: Lista IDs de serviços usados em itens_ordem. Externa: Filtra serviços NÃO presentes nessa lista.
SELECT descricao FROM servicos WHERE id_servico NOT IN (SELECT DISTINCT id_servico FROM itens_ordem);

-- =====================================================================
-- PARTE 12 - INTEGRIDADE DO BANCO (Testes de Falha)
-- Descomente uma linha por vez para validar as restrições.
-- =====================================================================
-- 1. CPF duplicado:
-- INSERT INTO clientes (nome, cpf, telefone) VALUES ('Teste', '11111111111', '4800000000'); 
-- Mecanismo de proteção: UNIQUE na coluna CPF.

-- 2. Veículo para cliente inexistente:
-- INSERT INTO veiculos (id_cliente, placa, marca, modelo, ano) VALUES (999, 'ZZZ9Z99', 'Fiat', 'Uno', 2010); 
-- Mecanismo de proteção: FOREIGN KEY (fk_veiculo_cliente).

-- 3. Preço inválido:
-- INSERT INTO servicos (descricao, preco) VALUES ('Serviço inválido', -50); 
-- Mecanismo de proteção: CHECK (ck_servico_preco).

-- 4. Exclusão de registro referenciado:
-- DELETE FROM clientes WHERE id_cliente = 1; 
-- Mecanismo de proteção: FOREIGN KEY em 'veiculos' (Restrição de integridade referencial).

-- 5. Ordem para veículo inexistente:
-- INSERT INTO ordens_servico (id_veiculo, id_mecanico) VALUES (999, 1);
-- Mecanismo de proteção: FOREIGN KEY (fk_ordem_veiculo).

-- =====================================================================
-- PARTE 13 - DESAFIO DE CONSULTA FINAL
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
-- =====================================================================
-- Explicação: A consulta realiza INNER JOIN entre mecânicos, ordens e itens 
-- para vincular o serviço executado ao mecânico responsável. O GROUP BY agrupa 
-- os resultados por mecânico. As funções de agregação COUNT(DISTINCT) contam 
-- as ordens únicas, SUM() soma a quantidade total de serviços e calcula o 
-- faturamento total. O ORDER BY valor_total DESC combinado com LIMIT 1 garante 
-- que apenas o mecânico com o maior faturamento seja exibido no topo.
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
-- PARTE 15 - TESTES E SITUAÇÕES INVÁLIDAS (Roteiro de 10 testes)
-- =====================================================================
-- TESTE 1 (Sucesso): Cadastrar cliente via procedure.
-- Operação: CALL cadastrar_cliente('Julio', '10987654321', '48999999999', 'julio@email.com');
-- Resultado Esperado: Sucesso (cliente cadastrado com ID novo).
-- Resultado Obtido: Sucesso. 1 row(s) affected. Cliente inserido com ID 11.

-- TESTE 2 (Erro): Cadastrar cliente com CPF repetido via procedure.
-- Operação: CALL cadastrar_cliente('Outro', '11111111111', '48999999999', 'x@x.com');
-- Resultado Esperado: Erro SQLSTATE 45000 (Mensagem: 'CPF já cadastrado.').
-- Resultado Obtido: Error Code: 1644. CPF já cadastrado.

-- TESTE 3 (Erro): Abrir ordem com veículo inexistente.
-- Operação: CALL abrir_ordem(999, 1, 'Teste de falha');
-- Resultado Esperado: Erro SQLSTATE 45000 (Mensagem: 'Veículo inexistente.').
-- Resultado Obtido: Error Code: 1644. Veículo inexistente.

-- TESTE 4 (Erro): Inserir preço inválido direto na tabela.
-- Operação: INSERT INTO servicos (descricao, preco) VALUES ('Erro', -10);
-- Resultado Esperado: Erro de violação de constraint CHECK (ck_servico_preco).
-- Resultado Obtido: Error Code: 3819. Check constraint 'ck_servico_preco' is violated.

-- TESTE 5 (Erro): Tentar mudar status para string inválida.
-- Operação: CALL alterar_status_ordem(6, 'pausada');
-- Resultado Esperado: Erro SQLSTATE 45000 (Mensagem: 'Status inválido.').
-- Resultado Obtido: Error Code: 1644. Status inválido.

-- TESTE 6 (Erro): Tentar adicionar item em ordem finalizada.
-- Operação: CALL adicionar_item_ordem(1, 2, 1);
-- Resultado Esperado: Erro SQLSTATE 45000 (Mensagem: 'Não é possível adicionar itens...').
-- Resultado Obtido: Error Code: 1644. Não é possível adicionar itens a ordem encerrada.

-- TESTE 7 (Erro): Tentar adicionar quantidade zero.
-- Operação: CALL adicionar_item_ordem(6, 1, 0);
-- Resultado Esperado: Erro SQLSTATE 45000 (Mensagem: 'Quantidade deve ser maior que zero.').
-- Resultado Obtido: Error Code: 1644. Quantidade deve ser maior que zero.

-- TESTE 8 (Sucesso): Adicionar item com quantidade correta em ordem aberta.
-- Operação: CALL adicionar_item_ordem(6, 2, 2);
-- Resultado Esperado: Sucesso (item adicionado; trigger preenche valor_unitario automaticamente).
-- Resultado Obtido: Sucesso. 1 row(s) affected. O trigger trg_valor_item preencheu o valor unitário com R$ 120,00.

-- TESTE 9 (Erro): Excluir cliente referenciado por veículo.
-- Operação: DELETE FROM clientes WHERE id_cliente = 1;
-- Resultado Esperado: Erro de Foreign Key Constraint (fk_veiculo_cliente).
-- Resultado Obtido: Error Code: 1451. Cannot delete or update a parent row: a foreign key constraint fails (`oficina`.`veiculos`, CONSTRAINT `fk_veiculo_cliente`).

-- TESTE 10 (Sucesso): Finalizar ordem aberta e ativar trigger de data.
-- Operação: CALL alterar_status_ordem(6, 'finalizada');
-- Resultado Esperado: Sucesso. Status muda e a Trigger trg_data_finalizacao preenche a data atual.
-- Resultado Obtido: Sucesso. 1 row(s) affected. O status mudou para 'finalizada' e a coluna data_finalizacao foi preenchida com NOW().