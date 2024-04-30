USE msdb;
GO

DECLARE @jobId BINARY(16);  -- Declara��o da vari�vel para armazenar o identificador do job

-- Criar o job
EXEC sp_add_job
    @job_name = N'ETL BazarTemTudo',  -- Nome do job
    @enabled = 1,                     -- Job habilitado
    @description = N'Executa tarefas ETL para BazarTemTudo',
    @notify_level_eventlog = 2,       -- Notificar quando falhar
    @job_id = @jobId OUTPUT;          -- Retorna o ID do job criado

-- Adicionar um passo ao job
EXEC sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'Executa SELECT',   -- Nome do passo
    @step_id = 1,
    @cmdexec_success_code = 0,
    @on_success_action = 1,           -- Prosseguir para o pr�ximo passo se tiver sucesso
    @on_fail_action = 2,              -- Encerrar com falha
    @retry_attempts = 0,
    @retry_interval = 0,
    @command = N'SELECT GETDATE()',   -- Comando T-SQL para execu��o
    @database_name = N'BazarTemTudo', -- Nome do banco de dados
    @subsystem = N'TSQL';

-- Criar um agendamento para o job
DECLARE @scheduleId INT;

EXEC sp_add_jobschedule
    @job_id = @jobId,
    @name = N'Agendamento Di�rio',    -- Nome do agendamento
    @enabled = 1,
    @freq_type = 4,                   -- Di�rio
    @freq_interval = 1,               -- Executar todos os dias
    @freq_subday_type = 1,            -- Subdivis�o do dia em que o job deve ser executado
    @freq_subday_interval = 0,        -- Intervalo das subdivis�es
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 0,
    @active_start_date = 20230101,    -- Data de in�cio do agendamento (AAAAMMDD)
    @active_end_date = 99991231,      -- Data de fim (opcional)
    @active_start_time = 0,           -- Hor�rio de in�cio di�rio
    @active_end_time = 235959,        -- Hor�rio de t�rmino di�rio
    @schedule_id = @scheduleId OUTPUT;

-- Associar o job ao agendamento
EXEC sp_attach_schedule
   @job_id = @jobId,
   @schedule_id = @scheduleId;

-- Ativar o job
EXEC sp_update_job
    @job_id = @jobId,
    @enabled = 1; -- Habilitar o job

GO
