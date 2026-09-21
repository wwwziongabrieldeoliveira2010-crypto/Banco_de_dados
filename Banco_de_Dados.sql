-- CONSTRUÇÃO DO BANCO DE DADOS
CREATE DATABASE ofmi;
USE ofmi;

-- 1. Tabela Clientes
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE
);

-- 2. Tabela Veículos
CREATE TABLE veiculos (
    id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
    placa VARCHAR(7) NOT NULL UNIQUE,
    modelo VARCHAR(50) NOT NULL,
    cliente_id INT NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id_cliente)
);

-- 3. Tabela Mecânicos
CREATE TABLE mecanicos (
    id_mecanico INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(50)
);

-- 4. Tabela Serviços
CREATE TABLE servicos (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(150) NOT NULL,
    preco DECIMAL(10,2) NOT NULL CHECK (preco >= 0)
);

-- 5. Tabela Ordens de Serviço
CREATE TABLE ordens_servico (
    id_ordem INT AUTO_INCREMENT PRIMARY KEY,
    data_abertura DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_finalizacao DATETIME NULL,
    status VARCHAR(20) DEFAULT 'ABERTA', -- Ex: ABERTA, EM ANDAMENTO, FINALIZADA, CANCELADA
    veiculo_id INT NOT NULL,
    mecanico_id INT NOT NULL,
    FOREIGN KEY (veiculo_id) REFERENCES veiculos(id_veiculo),
    FOREIGN KEY (mecanico_id) REFERENCES mecanicos(id_mecanico)
);

-- 6. Tabela Itens da Ordem de Serviço
CREATE TABLE itens_ordem (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    ordem_id INT NOT NULL,
    servico_id INT NOT NULL,
    preco_praticado DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (ordem_id) REFERENCES ordens_servico(id_ordem),
    FOREIGN KEY (servico_id) REFERENCES servicos(id_servico)
);

-- 7. Tabela de Histórico de Alteração de Preços 
CREATE TABLE historico_precos (
    id_historico INT AUTO_INCREMENT PRIMARY KEY,
    servico_id INT NOT NULL,
    preco_antigo DECIMAL(10,2) NOT NULL,
    preco_novo DECIMAL(10,2) NOT NULL,
    data_alteracao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (servico_id) REFERENCES servicos(id_servico)
);
--