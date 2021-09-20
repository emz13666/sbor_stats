-- phpMyAdmin SQL Dump
-- version 4.4.7
-- http://www.phpmyadmin.net
--
-- Хост: localhost
-- Время создания: Сен 20 2021 г., 08:25
-- Версия сервера: 5.5.23
-- Версия PHP: 5.3.10

SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES cp1251 */;

--
-- База данных: `ubiquiti`
--
CREATE DATABASE IF NOT EXISTS `ubiquiti` DEFAULT CHARACTER SET cp1251 COLLATE cp1251_general_cs;
USE `ubiquiti`;

DELIMITER $$
--
-- Процедуры
--
DROP PROCEDURE IF EXISTS `del_old_from_stats`$$
CREATE DEFINER=`root`@`%` PROCEDURE `del_old_from_stats`()
BEGIN
  DECLARE affected_rows INT DEFAULT 0;
  DECLARE count_rows INT DEFAULT 0;
  call resetLog ();
  REPEAT 
    DELETE FROM `stats_ap` where date<=DATE_SUB(curdate(),INTERVAL 70 day) LIMIT 50000;
    SELECT ROW_COUNT() INTO affected_rows;
    set count_rows = count_rows + affected_rows;
    if affected_rows <> 0 then 
      call dolog(concat_ws(': ','CountDeletedRowsIn_stats_ap',  count_rows));
    end if;
  UNTIL affected_rows=0
  END REPEAT;
  set count_rows=0;
  REPEAT
    DELETE FROM `stats_lte` where date<=DATE_SUB(curdate(),INTERVAL 70 day) LIMIT 50000;
    SELECT ROW_COUNT() INTO affected_rows;
    set count_rows = count_rows + affected_rows;
    if affected_rows <> 0  then 
      call dolog(concat_ws(': ','CountDeletedRowsIn_stats_lte',  count_rows));
	end if;
  UNTIL affected_rows=0
  END REPEAT;    
  set count_rows=0;
  REPEAT
    DELETE FROM `stats_ping` where date<=DATE_SUB(curdate(),INTERVAL 70 day) LIMIT 50000;
    SELECT ROW_COUNT() INTO affected_rows;
    set count_rows = count_rows + affected_rows;
    if affected_rows <> 0 then
      call dolog(concat_ws(': ','CountDeletedRowsIn_stats_ping',  count_rows));
	end if;
  UNTIL affected_rows=0
  END REPEAT;
  set count_rows=0;
  REPEAT
    delete /* 666 */ from `stats_status` where datetimeend<=DATE_SUB(curdate(),interval 70 day) LIMIT 50000;
    SELECT ROW_COUNT() INTO affected_rows;
    set count_rows = count_rows + affected_rows;
    if affected_rows <> 0 then
      call dolog(concat_ws(': ','CountDeletedRowsIn_stats_status',  count_rows));
	end if;
  UNTIL affected_rows=0
  END REPEAT;
  set count_rows=0;
  REPEAT
   DELETE /* proc del_old_from stats */ FROM `statss` where date<=DATE_SUB(curdate(),INTERVAL 70 day) limit 50000;
   SELECT ROW_COUNT() INTO affected_rows;
    set count_rows = count_rows + affected_rows;
    if affected_rows <> 0 then 
      call dolog(concat_ws(': ','CountDeletedRowsIn_statss',  count_rows));
	end if;
  UNTIL affected_rows>0  -- заменить на = после отладки!
  END REPEAT;
END$$

DROP PROCEDURE IF EXISTS `doLog`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `doLog`(in logMsg nvarchar(2048))
BEGIN  
  insert into log_debug_proc (msg) values(logMsg);
END$$

DROP PROCEDURE IF EXISTS `resetLog`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `resetLog`()
BEGIN   
    create table if not exists log_debug_proc (ts timestamp default current_timestamp, msg varchar(2048)) engine = myisam; 
    truncate table log_debug_proc;
END$$

DROP PROCEDURE IF EXISTS `test1`$$
CREATE DEFINER=`root`@`%` PROCEDURE `test1`()
BEGIN
	select id, date_time, sectorsize, xstart, ystart, xend, yend from wifi_stat_map into @id, @dttm, @sectorsize, @xstart, @ystart, @xend, @yend;
set @xcurr:=@xstart;
set @ycurr:=@ystart;
set @rowscount:=0;
set @colscount:=0;
WHILE @ycurr < @yend do
    while @xcurr<@xend do
		set @colscount:=@colscount+1;
		set @xcurr:=@xcurr+@sectorsize;
    end while;
    set @rowscount:=@rowscount+1;
    set @ycurr:=@ycurr+@sectorsize;
end while;
select @colscount, @rowscount;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `device`
--

DROP TABLE IF EXISTS `device`;
CREATE TABLE IF NOT EXISTS `device` (
  `ID` int(11) NOT NULL,
  `device_type` int(11) NOT NULL COMMENT 'Тип устройства',
  `serial` varchar(30) COLLATE cp1251_general_cs DEFAULT NULL COMMENT 'Серийный номер устройства',
  `status` int(11) NOT NULL COMMENT 'Ссылка на статус устройства',
  `equipment` int(11) DEFAULT NULL COMMENT 'Оборудовние, где установлено устройство',
  `comment` text COLLATE cp1251_general_cs NOT NULL,
  `device_link` int(11) NOT NULL COMMENT 'Ссылка на строку таблицы типа устройства'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Устройство';

-- --------------------------------------------------------

--
-- Структура таблицы `device_events`
--

DROP TABLE IF EXISTS `device_events`;
CREATE TABLE IF NOT EXISTS `device_events` (
  `ID` int(11) NOT NULL,
  `device` int(11) NOT NULL,
  `equipment` int(11) NOT NULL,
  `ref_event_type` int(11) NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='События по снятию и установке устройств';

-- --------------------------------------------------------

--
-- Структура таблицы `equipment`
--

DROP TABLE IF EXISTS `equipment`;
CREATE TABLE IF NOT EXISTS `equipment` (
  `id` bigint(20) unsigned NOT NULL,
  `name` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `equipment_type` int(11) NOT NULL,
  `ip_address` varchar(50) COLLATE cp1251_general_cs NOT NULL DEFAULT '' COMMENT 'IP адрес булита',
  `ip_pc` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL COMMENT 'IP адрес бортового компьютера',
  `ip_alias` varchar(15) COLLATE cp1251_general_cs DEFAULT NULL COMMENT 'IP адрес булита СЗМ во взрывцехе',
  `comment` text COLLATE cp1251_general_cs,
  `useInMonitoring` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Флаг использования в программе мониторинга',
  `LastGPSDateTime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `equipment_interfaces`
--

DROP TABLE IF EXISTS `equipment_interfaces`;
CREATE TABLE IF NOT EXISTS `equipment_interfaces` (
  `id` int(11) NOT NULL,
  `equipment` int(11) NOT NULL COMMENT 'Оборудование',
  `interface` int(11) NOT NULL COMMENT 'Ссылка на ref_interface'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Интерфейсы, которые имеются на оборудовании';

-- --------------------------------------------------------

--
-- Структура таблицы `hist_maps`
--

DROP TABLE IF EXISTS `hist_maps`;
CREATE TABLE IF NOT EXISTS `hist_maps` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Список планов карьера';

-- --------------------------------------------------------

--
-- Структура таблицы `hist_map_points`
--

DROP TABLE IF EXISTS `hist_map_points`;
CREATE TABLE IF NOT EXISTS `hist_map_points` (
  `id` int(11) NOT NULL,
  `map` int(11) NOT NULL COMMENT 'Ссылка на таблицу hist_maps',
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `name` varchar(20) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='История координат объектов';

-- --------------------------------------------------------

--
-- Структура таблицы `hist_map_roads`
--

DROP TABLE IF EXISTS `hist_map_roads`;
CREATE TABLE IF NOT EXISTS `hist_map_roads` (
  `id` int(11) NOT NULL,
  `map` int(11) NOT NULL COMMENT 'Ссылка на hist_map',
  `name_start` varchar(20) COLLATE cp1251_general_cs NOT NULL,
  `name_end` varchar(20) COLLATE cp1251_general_cs NOT NULL,
  `xstart` int(11) NOT NULL,
  `ystart` int(11) NOT NULL,
  `xend` int(11) NOT NULL,
  `yend` int(11) NOT NULL,
  `p1x` int(11) DEFAULT NULL,
  `p1y` int(11) DEFAULT NULL,
  `p2x` int(11) DEFAULT NULL,
  `p2y` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Статистика изменения таблицы дорог';

-- --------------------------------------------------------

--
-- Структура таблицы `interface_monitoring_off`
--

DROP TABLE IF EXISTS `interface_monitoring_off`;
CREATE TABLE IF NOT EXISTS `interface_monitoring_off` (
  `id` int(11) NOT NULL,
  `equipment` int(11) NOT NULL COMMENT 'Оборудование, на котором произошло отключение мониторинга',
  `ref_interface` int(11) NOT NULL COMMENT 'Интерфейс с отключенным мониторингом',
  `Active` tinyint(4) NOT NULL DEFAULT '1' COMMENT 'Является ли отключение активным',
  `datetimestart` datetime NOT NULL,
  `datetimeend` datetime DEFAULT NULL,
  `reason` varchar(255) COLLATE cp1251_general_cs NOT NULL COMMENT 'Причина неработы интерфейса',
  `reason_category` tinyint(1) NOT NULL DEFAULT '0',
  `FIO` varchar(100) COLLATE cp1251_general_cs NOT NULL COMMENT 'ФИО сообщившего'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Таблица отключений мониторинга';

-- --------------------------------------------------------

--
-- Структура таблицы `kobus_current_breaks`
--

DROP TABLE IF EXISTS `kobus_current_breaks`;
CREATE TABLE IF NOT EXISTS `kobus_current_breaks` (
  `breakId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Список статусов из kobus.breaks.breakage_history, у которых время окончания null';

-- --------------------------------------------------------

--
-- Структура таблицы `kobus_export`
--

DROP TABLE IF EXISTS `kobus_export`;
CREATE TABLE IF NOT EXISTS `kobus_export` (
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `LastBreakageHistoryID` bigint(20) DEFAULT NULL COMMENT 'Последний ID из БД kobus_lgok таблица breaks.breakage_history'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Переменные, в которых содержится информация о выгрузках';

-- --------------------------------------------------------

--
-- Структура таблицы `kobus_pribors`
--

DROP TABLE IF EXISTS `kobus_pribors`;
CREATE TABLE IF NOT EXISTS `kobus_pribors` (
  `id_equipment` int(11) NOT NULL,
  `pribor_id_kobus` int(11) NOT NULL,
  `last_gps_writed` datetime NOT NULL COMMENT 'Дата и время последней обработанной записи из gps.online_position'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Сопоставление оборудования equipment и id бурстанков из БД kobus public.pribors';

-- --------------------------------------------------------

--
-- Структура таблицы `log`
--

DROP TABLE IF EXISTS `log`;
CREATE TABLE IF NOT EXISTS `log` (
  `datetime` datetime NOT NULL,
  `message` char(255) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `log_analize_wifi_by_equip`
--

DROP TABLE IF EXISTS `log_analize_wifi_by_equip`;
CREATE TABLE IF NOT EXISTS `log_analize_wifi_by_equip` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Список дат, за которые выполнен анализ WiFi по оборудованию';

-- --------------------------------------------------------

--
-- Структура таблицы `log_debug_proc`
--

DROP TABLE IF EXISTS `log_debug_proc`;
CREATE TABLE IF NOT EXISTS `log_debug_proc` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `msg` varchar(2048) COLLATE cp1251_general_cs DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `lte`
--

DROP TABLE IF EXISTS `lte`;
CREATE TABLE IF NOT EXISTS `lte` (
  `id` bigint(20) unsigned NOT NULL,
  `name` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `ip_lte` varchar(50) COLLATE cp1251_general_cs NOT NULL,
  `ip_vpn` varchar(50) COLLATE cp1251_general_cs NOT NULL,
  `mac_eth01` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `mac_eth02` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `mac_ovpn` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `place_install` varchar(100) COLLATE cp1251_general_cs DEFAULT NULL,
  `firmware` varchar(100) COLLATE cp1251_general_cs NOT NULL,
  `id_equipment` bigint(20) unsigned DEFAULT NULL,
  `model_lte` varchar(100) COLLATE cp1251_general_cs DEFAULT NULL,
  `serial_lte` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `serial_modem` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `imei_modem` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `model_modem` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `prim` varchar(100) COLLATE cp1251_general_cs DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `modems`
--

DROP TABLE IF EXISTS `modems`;
CREATE TABLE IF NOT EXISTS `modems` (
  `id_modem` bigint(20) unsigned NOT NULL,
  `is_access_point` tinyint(4) NOT NULL DEFAULT '0',
  `name` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `ip_address` varchar(50) COLLATE cp1251_general_cs NOT NULL DEFAULT '',
  `mac_address` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `place_install` varchar(255) COLLATE cp1251_general_cs DEFAULT NULL,
  `power` tinyint(4) NOT NULL DEFAULT '20',
  `prim` varchar(255) COLLATE cp1251_general_cs DEFAULT NULL,
  `color` bigint(20) NOT NULL DEFAULT '0',
  `online` tinyint(4) NOT NULL DEFAULT '0',
  `firmware` char(8) COLLATE cp1251_general_cs NOT NULL DEFAULT '5.5',
  `id_equipment` bigint(20) unsigned DEFAULT NULL,
  `is_ap_repeater` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `mac_wds_peer` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `modems_test`
--

DROP TABLE IF EXISTS `modems_test`;
CREATE TABLE IF NOT EXISTS `modems_test` (
  `id_modem` bigint(20) unsigned NOT NULL DEFAULT '0',
  `is_access_point` tinyint(4) NOT NULL DEFAULT '0',
  `name` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `ip_address` varchar(50) COLLATE cp1251_general_cs NOT NULL DEFAULT '',
  `mac_address` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `place_install` varchar(255) COLLATE cp1251_general_cs DEFAULT NULL,
  `power` tinyint(4) NOT NULL DEFAULT '20',
  `prim` varchar(255) COLLATE cp1251_general_cs DEFAULT NULL,
  `color` bigint(20) NOT NULL DEFAULT '0',
  `online` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `planned_works`
--

DROP TABLE IF EXISTS `planned_works`;
CREATE TABLE IF NOT EXISTS `planned_works` (
  `id` int(11) NOT NULL,
  `equipment` int(11) NOT NULL COMMENT 'Ссылка на оборудование',
  `workname` varchar(255) COLLATE cp1251_general_cs NOT NULL,
  `status` int(11) NOT NULL COMMENT 'Ссылка на статус работы',
  `lastActionsDate` datetime NOT NULL COMMENT 'Дата последнего изменения',
  `CreatedDate` datetime NOT NULL COMMENT 'Дата создания работы',
  `comments` text COLLATE cp1251_general_cs,
  `userid` int(11) NOT NULL COMMENT 'Ссылка на users',
  `groupid` int(11) NOT NULL COMMENT 'Ссылка на usergroups',
  `access` int(11) NOT NULL COMMENT 'Тип доступа. Ссылка на ref_accesstype'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Таблица запланированных работ';

-- --------------------------------------------------------

--
-- Структура таблицы `planned_works_waitactions`
--

DROP TABLE IF EXISTS `planned_works_waitactions`;
CREATE TABLE IF NOT EXISTS `planned_works_waitactions` (
  `id` int(11) NOT NULL,
  `work` int(11) NOT NULL COMMENT 'Ссылка на Planned_works',
  `waitAction` int(11) NOT NULL COMMENT 'Ссылка на ref_waitactions'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Таблица списка наступивших действий, к которым привязана выполняемая работа';

-- --------------------------------------------------------

--
-- Структура таблицы `ptx`
--

DROP TABLE IF EXISTS `ptx`;
CREATE TABLE IF NOT EXISTS `ptx` (
  `id_ptx` bigint(20) unsigned NOT NULL,
  `id_modem` bigint(20) unsigned DEFAULT NULL,
  `serial` varchar(20) COLLATE cp1251_general_cs DEFAULT NULL,
  `ip_address` varchar(15) COLLATE cp1251_general_cs DEFAULT NULL,
  `os_ver` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `dispatch_ver` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `oem_driver_ver` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `prim` varchar(255) COLLATE cp1251_general_cs DEFAULT NULL,
  `mac_address` varchar(20) COLLATE cp1251_general_cs DEFAULT NULL,
  `id_equipment` bigint(20) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `ptx_history`
--

DROP TABLE IF EXISTS `ptx_history`;
CREATE TABLE IF NOT EXISTS `ptx_history` (
  `id` bigint(20) unsigned NOT NULL,
  `id_ptx` bigint(20) NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `info` varchar(255) COLLATE cp1251_general_cs DEFAULT NULL,
  `place_install` varchar(50) COLLATE cp1251_general_cs NOT NULL COMMENT 'место предыдущей установки',
  `place_install_new` varchar(100) COLLATE cp1251_general_cs NOT NULL COMMENT 'место установки '
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `ref_accesstype`
--

DROP TABLE IF EXISTS `ref_accesstype`;
CREATE TABLE IF NOT EXISTS `ref_accesstype` (
  `id` int(11) NOT NULL,
  `name` varchar(20) COLLATE cp1251_general_cs NOT NULL,
  `description` varchar(255) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Тип доступа. ';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_connect_type`
--

DROP TABLE IF EXISTS `ref_connect_type`;
CREATE TABLE IF NOT EXISTS `ref_connect_type` (
  `id` int(11) NOT NULL,
  `name` varchar(50) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Тип подключения доп. систем';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_device_status`
--

DROP TABLE IF EXISTS `ref_device_status`;
CREATE TABLE IF NOT EXISTS `ref_device_status` (
  `ID` int(11) NOT NULL,
  `Name` varchar(50) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Спрвочник статусов устройств';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_device_type`
--

DROP TABLE IF EXISTS `ref_device_type`;
CREATE TABLE IF NOT EXISTS `ref_device_type` (
  `ID` int(11) NOT NULL,
  `Name` varchar(100) COLLATE cp1251_general_cs NOT NULL,
  `ShortName` varchar(30) COLLATE cp1251_general_cs DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Типы устройств';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_equipment_type`
--

DROP TABLE IF EXISTS `ref_equipment_type`;
CREATE TABLE IF NOT EXISTS `ref_equipment_type` (
  `id` int(11) NOT NULL,
  `name` varchar(200) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `ref_event_type`
--

DROP TABLE IF EXISTS `ref_event_type`;
CREATE TABLE IF NOT EXISTS `ref_event_type` (
  `ID` int(11) NOT NULL,
  `name` varchar(20) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Справочник типов событий';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_interface`
--

DROP TABLE IF EXISTS `ref_interface`;
CREATE TABLE IF NOT EXISTS `ref_interface` (
  `id` int(11) NOT NULL,
  `Name` varchar(20) COLLATE cp1251_general_cs NOT NULL COMMENT 'Код интерфейса',
  `FullName` varchar(50) COLLATE cp1251_general_cs NOT NULL,
  `Category` int(11) DEFAULT NULL COMMENT 'Категория интерфейса. Ссылка на таблицу ref_interface_category'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `ref_interface_category`
--

DROP TABLE IF EXISTS `ref_interface_category`;
CREATE TABLE IF NOT EXISTS `ref_interface_category` (
  `id` int(11) NOT NULL,
  `shortName` varchar(10) COLLATE cp1251_general_cs NOT NULL COMMENT 'Короткое имя категории',
  `FullName` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL COMMENT 'Полное имя категории'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Таблица категорий интерфейсов';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_monitor_off_category`
--

DROP TABLE IF EXISTS `ref_monitor_off_category`;
CREATE TABLE IF NOT EXISTS `ref_monitor_off_category` (
  `id` int(11) NOT NULL,
  `Name` varchar(15) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Справочник категорий причин отключения';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_statss_status`
--

DROP TABLE IF EXISTS `ref_statss_status`;
CREATE TABLE IF NOT EXISTS `ref_statss_status` (
  `id` int(11) NOT NULL,
  `name` varchar(30) COLLATE cp1251_general_cs DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Статусы оборудования для статистики связи (таблица statss)';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_system`
--

DROP TABLE IF EXISTS `ref_system`;
CREATE TABLE IF NOT EXISTS `ref_system` (
  `id` int(11) NOT NULL,
  `name` varchar(20) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Таблица обслуживаемых систем';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_waitactions`
--

DROP TABLE IF EXISTS `ref_waitactions`;
CREATE TABLE IF NOT EXISTS `ref_waitactions` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Справочник ожиданий для мобильного оборудования';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_works`
--

DROP TABLE IF EXISTS `ref_works`;
CREATE TABLE IF NOT EXISTS `ref_works` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Список работ';

-- --------------------------------------------------------

--
-- Структура таблицы `ref_work_status`
--

DROP TABLE IF EXISTS `ref_work_status`;
CREATE TABLE IF NOT EXISTS `ref_work_status` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Статусы выполнения работ';

-- --------------------------------------------------------

--
-- Структура таблицы `repairs`
--

DROP TABLE IF EXISTS `repairs`;
CREATE TABLE IF NOT EXISTS `repairs` (
  `ID` int(11) NOT NULL,
  `device` int(11) NOT NULL,
  `fail_date` date NOT NULL,
  `link_to_doc` varchar(100) COLLATE cp1251_general_cs DEFAULT NULL COMMENT 'Ссылка на местоположение файла акта',
  `sending_date` date DEFAULT NULL,
  `ticket` int(11) NOT NULL,
  `transport_num` varchar(20) COLLATE cp1251_general_cs DEFAULT NULL,
  `return_date` date NOT NULL,
  `complete` tinyint(1) NOT NULL COMMENT 'Признак успешного ремонта'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `statss`
--

DROP TABLE IF EXISTS `statss`;
CREATE TABLE IF NOT EXISTS `statss` (
  `id` int(10) unsigned NOT NULL,
  `id_equipment` bigint(20) NOT NULL DEFAULT '0',
  `id_modem` int(10) unsigned NOT NULL DEFAULT '0',
  `mac_ap` char(20) COLLATE cp1251_general_cs NOT NULL DEFAULT '',
  `signal_level` tinyint(4) NOT NULL DEFAULT '0',
  `date` date NOT NULL DEFAULT '0000-00-00',
  `time` time NOT NULL DEFAULT '00:00:00',
  `datetime` datetime DEFAULT NULL,
  `status` smallint(6) NOT NULL DEFAULT '0',
  `num_sats` smallint(6) NOT NULL DEFAULT '0',
  `x` smallint(6) DEFAULT '0',
  `y` smallint(6) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `stats_ap`
--

DROP TABLE IF EXISTS `stats_ap`;
CREATE TABLE IF NOT EXISTS `stats_ap` (
  `id` bigint(20) unsigned NOT NULL,
  `id_modem` int(10) unsigned NOT NULL DEFAULT '0',
  `id_equipment` bigint(20) NOT NULL DEFAULT '0',
  `signal_level` tinyint(4) NOT NULL DEFAULT '0',
  `date` date NOT NULL,
  `time` time NOT NULL,
  `datetime` datetime DEFAULT NULL,
  `loadavg` smallint(4) NOT NULL DEFAULT '0',
  `memfree` mediumint(5) unsigned NOT NULL DEFAULT '0',
  `rx_octets_eth0` bigint(20) unsigned NOT NULL DEFAULT '0',
  `tx_octets_eth0` bigint(20) unsigned NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `stats_fail_auto_tmp`
--

DROP TABLE IF EXISTS `stats_fail_auto_tmp`;
CREATE TABLE IF NOT EXISTS `stats_fail_auto_tmp` (
  `id` bigint(20) unsigned NOT NULL,
  `name` char(10) COLLATE cp1251_general_cs DEFAULT NULL,
  `percent` double NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `stats_lte`
--

DROP TABLE IF EXISTS `stats_lte`;
CREATE TABLE IF NOT EXISTS `stats_lte` (
  `id` bigint(20) unsigned NOT NULL,
  `id_equipment` bigint(20) NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `datetime` datetime NOT NULL,
  `signal_rsrp` smallint(6) DEFAULT NULL,
  `signal_rsrq` smallint(6) DEFAULT NULL,
  `signal_sinr` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `stats_ping`
--

DROP TABLE IF EXISTS `stats_ping`;
CREATE TABLE IF NOT EXISTS `stats_ping` (
  `id` bigint(20) unsigned NOT NULL,
  `id_equipment` bigint(20) unsigned NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `datetime` datetime NOT NULL,
  `time_ping` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `stats_status`
--

DROP TABLE IF EXISTS `stats_status`;
CREATE TABLE IF NOT EXISTS `stats_status` (
  `id` bigint(20) NOT NULL,
  `id_equipment` bigint(20) unsigned NOT NULL,
  `status` int(11) NOT NULL,
  `datetimestart` datetime NOT NULL,
  `datetimeend` datetime NOT NULL,
  `asu_id` varchar(20) COLLATE cp1251_general_cs NOT NULL COMMENT 'ID в системе, откуда загружаем'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Статусы техники';

-- --------------------------------------------------------

--
-- Структура таблицы `stats_status_kobus_current_breaks`
--

DROP TABLE IF EXISTS `stats_status_kobus_current_breaks`;
CREATE TABLE IF NOT EXISTS `stats_status_kobus_current_breaks` (
  `breakId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Список статусов из kobus.breaks.breakage_history, у которых время окончания null';

-- --------------------------------------------------------

--
-- Структура таблицы `stats_status_settings_kobus`
--

DROP TABLE IF EXISTS `stats_status_settings_kobus`;
CREATE TABLE IF NOT EXISTS `stats_status_settings_kobus` (
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `LastBreakageHistoryID` bigint(20) DEFAULT NULL COMMENT 'Последний ID из БД kobus_lgok таблица breaks.breakage_history'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Переменные, в которых содержится информация о выгрузках';

-- --------------------------------------------------------

--
-- Структура таблицы `stats_status_settings_modular`
--

DROP TABLE IF EXISTS `stats_status_settings_modular`;
CREATE TABLE IF NOT EXISTS `stats_status_settings_modular` (
  `id` int(11) NOT NULL,
  `shiftindex` int(11) NOT NULL COMMENT 'Смена, раньше которой все обработано',
  `minendtime` int(11) NOT NULL COMMENT 'Время окончания статуса, до которого все обработано'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Настройки ';

-- --------------------------------------------------------

--
-- Структура таблицы `usergroups`
--

DROP TABLE IF EXISTS `usergroups`;
CREATE TABLE IF NOT EXISTS `usergroups` (
  `id` int(11) NOT NULL,
  `groupname` varchar(255) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Группы пользователей';

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `ID` int(11) NOT NULL,
  `Login` varchar(50) COLLATE cp1251_general_cs NOT NULL,
  `password_md5` varchar(200) COLLATE cp1251_general_cs DEFAULT NULL,
  `FIO` varchar(100) COLLATE cp1251_general_cs DEFAULT NULL,
  `groupid` int(11) DEFAULT NULL COMMENT 'Ссылка на usergroups'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Таблица пользоватлей системы';

-- --------------------------------------------------------

--
-- Структура таблицы `wifi_log`
--

DROP TABLE IF EXISTS `wifi_log`;
CREATE TABLE IF NOT EXISTS `wifi_log` (
  `id` bigint(20) unsigned NOT NULL,
  `datetime` datetime NOT NULL,
  `action` char(3) COLLATE cp1251_general_cs NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs;

-- --------------------------------------------------------

--
-- Структура таблицы `wifi_stat_equipment`
--

DROP TABLE IF EXISTS `wifi_stat_equipment`;
CREATE TABLE IF NOT EXISTS `wifi_stat_equipment` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL,
  `hour` tinyint(4) NOT NULL,
  `equipment` int(11) NOT NULL,
  `count_all` int(11) NOT NULL COMMENT 'Общее количество точек',
  `count_success` int(11) NOT NULL COMMENT 'Количество успешных (уровень сигнала > -100)',
  `signal_avg` float NOT NULL COMMENT 'Средний уровень сигнала'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Статистика по WiFi для оборудования';

-- --------------------------------------------------------

--
-- Структура таблицы `wifi_stat_map`
--

DROP TABLE IF EXISTS `wifi_stat_map`;
CREATE TABLE IF NOT EXISTS `wifi_stat_map` (
  `id` int(11) NOT NULL,
  `date_time` datetime NOT NULL COMMENT 'Дата и время настроек',
  `xstart` int(11) NOT NULL,
  `ystart` int(11) NOT NULL,
  `xend` int(11) NOT NULL,
  `yend` int(11) NOT NULL,
  `sectorsize` smallint(6) NOT NULL COMMENT 'Размер сектора'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Карты для построения посекторной статистики';

--
-- Триггеры `wifi_stat_map`
--
DROP TRIGGER IF EXISTS `ONINSERT_MAP`;
DELIMITER $$
CREATE TRIGGER `ONINSERT_MAP` AFTER INSERT ON `wifi_stat_map`
 FOR EACH ROW BEGIN
set @ycurr:=NEW.ystart;
set @rowscount:=0;
set @colscount:=0;
WHILE @ycurr < (NEW.yend+NEW.sectorsize) do
	set @xcurr:=NEW.xstart;
    while @xcurr< (NEW.xend+NEW.sectorsize) do
		insert into wifi_stat_map_sectors (map_id,xstart,ystart,xend,yend) values (NEW.id,@xcurr,@ycurr,@xcurr+NEW.sectorsize-1,@ycurr+NEW.sectorsize-1);
		set @xcurr:=@xcurr+NEW.sectorsize;
    end while;
    set @ycurr:=@ycurr+NEW.sectorsize;
end while;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `wifi_stat_map_data`
--

DROP TABLE IF EXISTS `wifi_stat_map_data`;
CREATE TABLE IF NOT EXISTS `wifi_stat_map_data` (
  `id` int(11) NOT NULL,
  `equipment_id` bigint(20) unsigned NOT NULL,
  `map_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `hour` tinyint(4) NOT NULL,
  `AP_id` bigint(20) unsigned DEFAULT NULL COMMENT 'Базовая станция. Ссылка на modems',
  `sector_id` int(4) NOT NULL,
  `count_all` int(11) NOT NULL,
  `count_success` int(11) NOT NULL,
  `signal_avg` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Статистика Wifi по карте карьера';

-- --------------------------------------------------------

--
-- Структура таблицы `wifi_stat_map_log`
--

DROP TABLE IF EXISTS `wifi_stat_map_log`;
CREATE TABLE IF NOT EXISTS `wifi_stat_map_log` (
  `map_id` int(11) NOT NULL,
  `id_equipment` bigint(20) unsigned NOT NULL,
  `lastGPSCalculated` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Таблица последних обработанных координат при построении карты карьера';

-- --------------------------------------------------------

--
-- Структура таблицы `wifi_stat_map_sectors`
--

DROP TABLE IF EXISTS `wifi_stat_map_sectors`;
CREATE TABLE IF NOT EXISTS `wifi_stat_map_sectors` (
  `id` int(11) NOT NULL,
  `map_id` int(11) NOT NULL,
  `xstart` int(11) NOT NULL,
  `ystart` int(11) NOT NULL,
  `xend` int(11) NOT NULL,
  `yend` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='В таблице хранятся сектора карты карьера из wifi_stat_map';

-- --------------------------------------------------------

--
-- Структура таблицы `workers`
--

DROP TABLE IF EXISTS `workers`;
CREATE TABLE IF NOT EXISTS `workers` (
  `ID` int(11) NOT NULL,
  `Family` varchar(50) COLLATE cp1251_general_cs NOT NULL,
  `Name` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `Second_Name` varchar(50) COLLATE cp1251_general_cs DEFAULT NULL,
  `user` int(11) DEFAULT NULL COMMENT 'Ссылка на таблицу пользовтелей'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Работники учствка';

-- --------------------------------------------------------

--
-- Структура таблицы `workexecution`
--

DROP TABLE IF EXISTS `workexecution`;
CREATE TABLE IF NOT EXISTS `workexecution` (
  `ID` int(11) NOT NULL,
  `WorkOrder` int(11) NOT NULL,
  `Date` date NOT NULL,
  `Time` time NOT NULL,
  `comment` text COLLATE cp1251_general_cs
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Выполнение работ';

-- --------------------------------------------------------

--
-- Структура таблицы `workexecution_workers`
--

DROP TABLE IF EXISTS `workexecution_workers`;
CREATE TABLE IF NOT EXISTS `workexecution_workers` (
  `ID` int(11) NOT NULL,
  `WorkExecution` int(11) NOT NULL COMMENT 'Работа',
  `Worker` int(11) NOT NULL COMMENT 'Работник, выполнявший работу'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Какие работники выполняли какие работы';

-- --------------------------------------------------------

--
-- Структура таблицы `workorders`
--

DROP TABLE IF EXISTS `workorders`;
CREATE TABLE IF NOT EXISTS `workorders` (
  `ID` int(11) NOT NULL,
  `Date` date NOT NULL,
  `Time` time NOT NULL,
  `equipment_type` int(11) DEFAULT NULL COMMENT 'Ссылка на тип оборудовния',
  `equipment` int(11) DEFAULT NULL COMMENT 'ID оборудования',
  `failure` int(11) NOT NULL,
  `completed` tinyint(1) NOT NULL COMMENT 'Статус заявки. Выполнено или нет'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251 COLLATE=cp1251_general_cs COMMENT='Заявки на выполнение работ';

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `device_events`
--
ALTER TABLE `device_events`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `equipment`
--
ALTER TABLE `equipment`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `equipment_interfaces`
--
ALTER TABLE `equipment_interfaces`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `EQIntfc` (`equipment`,`interface`);

--
-- Индексы таблицы `hist_maps`
--
ALTER TABLE `hist_maps`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `hist_map_points`
--
ALTER TABLE `hist_map_points`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `hist_map_roads`
--
ALTER TABLE `hist_map_roads`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `interface_monitoring_off`
--
ALTER TABLE `interface_monitoring_off`
  ADD PRIMARY KEY (`id`),
  ADD KEY `equipment` (`equipment`,`ref_interface`);

--
-- Индексы таблицы `kobus_current_breaks`
--
ALTER TABLE `kobus_current_breaks`
  ADD PRIMARY KEY (`breakId`);

--
-- Индексы таблицы `kobus_pribors`
--
ALTER TABLE `kobus_pribors`
  ADD UNIQUE KEY `id_equipment` (`id_equipment`);

--
-- Индексы таблицы `log`
--
ALTER TABLE `log`
  ADD PRIMARY KEY (`datetime`);

--
-- Индексы таблицы `log_analize_wifi_by_equip`
--
ALTER TABLE `log_analize_wifi_by_equip`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `date` (`date`);

--
-- Индексы таблицы `lte`
--
ALTER TABLE `lte`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `modems`
--
ALTER TABLE `modems`
  ADD PRIMARY KEY (`id_modem`);

--
-- Индексы таблицы `planned_works`
--
ALTER TABLE `planned_works`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `StatusEquipment` (`status`,`equipment`),
  ADD KEY `status` (`status`);

--
-- Индексы таблицы `planned_works_waitactions`
--
ALTER TABLE `planned_works_waitactions`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ptx`
--
ALTER TABLE `ptx`
  ADD PRIMARY KEY (`id_ptx`);

--
-- Индексы таблицы `ptx_history`
--
ALTER TABLE `ptx_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_ptx` (`id_ptx`);

--
-- Индексы таблицы `ref_accesstype`
--
ALTER TABLE `ref_accesstype`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_connect_type`
--
ALTER TABLE `ref_connect_type`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_device_status`
--
ALTER TABLE `ref_device_status`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `ref_device_type`
--
ALTER TABLE `ref_device_type`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `ref_equipment_type`
--
ALTER TABLE `ref_equipment_type`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_event_type`
--
ALTER TABLE `ref_event_type`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `ref_interface`
--
ALTER TABLE `ref_interface`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_interface_category`
--
ALTER TABLE `ref_interface_category`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_monitor_off_category`
--
ALTER TABLE `ref_monitor_off_category`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_statss_status`
--
ALTER TABLE `ref_statss_status`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_system`
--
ALTER TABLE `ref_system`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_waitactions`
--
ALTER TABLE `ref_waitactions`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `ref_works`
--
ALTER TABLE `ref_works`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Индексы таблицы `ref_work_status`
--
ALTER TABLE `ref_work_status`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `repairs`
--
ALTER TABLE `repairs`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `statss`
--
ALTER TABLE `statss`
  ADD PRIMARY KEY (`id`),
  ADD KEY `mac_ap` (`mac_ap`),
  ADD KEY `x` (`x`),
  ADD KEY `date_idmodem` (`date`,`id_modem`,`time`),
  ADD KEY `date` (`date`,`x`,`y`),
  ADD KEY `id_modem` (`id_modem`,`date`,`status`) USING BTREE,
  ADD KEY `datetime` (`id_equipment`,`datetime`) USING BTREE,
  ADD KEY `datetime_` (`datetime`);

--
-- Индексы таблицы `stats_ap`
--
ALTER TABLE `stats_ap`
  ADD PRIMARY KEY (`id`),
  ADD KEY `date_id_modem_time` (`date`,`id_modem`,`time`),
  ADD KEY `datetime` (`datetime`) USING BTREE,
  ADD KEY `id_equipment` (`id_equipment`);

--
-- Индексы таблицы `stats_fail_auto_tmp`
--
ALTER TABLE `stats_fail_auto_tmp`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `stats_lte`
--
ALTER TABLE `stats_lte`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_equip__datetime` (`id_equipment`,`datetime`) USING BTREE;

--
-- Индексы таблицы `stats_ping`
--
ALTER TABLE `stats_ping`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_equipment` (`id_equipment`),
  ADD KEY `date` (`date`),
  ADD KEY `time` (`time`),
  ADD KEY `index_datetime` (`id`) USING BTREE,
  ADD KEY `idx_stats_ping_id_equipment_datetime` (`id_equipment`,`datetime`);

--
-- Индексы таблицы `stats_status`
--
ALTER TABLE `stats_status`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_equipment` (`id_equipment`),
  ADD KEY `status` (`status`),
  ADD KEY `asu_id` (`asu_id`),
  ADD KEY `datetimeend_index` (`datetimeend`),
  ADD KEY `id_equipment_datetimeend` (`id_equipment`,`datetimeend`);

--
-- Индексы таблицы `stats_status_kobus_current_breaks`
--
ALTER TABLE `stats_status_kobus_current_breaks`
  ADD PRIMARY KEY (`breakId`);

--
-- Индексы таблицы `stats_status_settings_modular`
--
ALTER TABLE `stats_status_settings_modular`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `usergroups`
--
ALTER TABLE `usergroups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `groupname` (`groupname`);

--
-- Индексы таблицы `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `Login` (`Login`);

--
-- Индексы таблицы `wifi_log`
--
ALTER TABLE `wifi_log`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `wifi_stat_equipment`
--
ALTER TABLE `wifi_stat_equipment`
  ADD PRIMARY KEY (`id`),
  ADD KEY `dateEquip` (`date`,`equipment`);

--
-- Индексы таблицы `wifi_stat_map`
--
ALTER TABLE `wifi_stat_map`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `wifi_stat_map_data`
--
ALTER TABLE `wifi_stat_map_data`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `wifi_stat_map_log`
--
ALTER TABLE `wifi_stat_map_log`
  ADD PRIMARY KEY (`map_id`,`id_equipment`),
  ADD KEY `id_equipment` (`id_equipment`);

--
-- Индексы таблицы `wifi_stat_map_sectors`
--
ALTER TABLE `wifi_stat_map_sectors`
  ADD PRIMARY KEY (`id`),
  ADD KEY `map_id` (`map_id`);

--
-- Индексы таблицы `workers`
--
ALTER TABLE `workers`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `workexecution`
--
ALTER TABLE `workexecution`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `workexecution_workers`
--
ALTER TABLE `workexecution_workers`
  ADD PRIMARY KEY (`ID`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `device_events`
--
ALTER TABLE `device_events`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `equipment`
--
ALTER TABLE `equipment`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `equipment_interfaces`
--
ALTER TABLE `equipment_interfaces`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `hist_maps`
--
ALTER TABLE `hist_maps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `hist_map_points`
--
ALTER TABLE `hist_map_points`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `hist_map_roads`
--
ALTER TABLE `hist_map_roads`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `interface_monitoring_off`
--
ALTER TABLE `interface_monitoring_off`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `log_analize_wifi_by_equip`
--
ALTER TABLE `log_analize_wifi_by_equip`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `lte`
--
ALTER TABLE `lte`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `modems`
--
ALTER TABLE `modems`
  MODIFY `id_modem` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `planned_works`
--
ALTER TABLE `planned_works`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ptx`
--
ALTER TABLE `ptx`
  MODIFY `id_ptx` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ptx_history`
--
ALTER TABLE `ptx_history`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_accesstype`
--
ALTER TABLE `ref_accesstype`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_connect_type`
--
ALTER TABLE `ref_connect_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_device_status`
--
ALTER TABLE `ref_device_status`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_device_type`
--
ALTER TABLE `ref_device_type`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_equipment_type`
--
ALTER TABLE `ref_equipment_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_event_type`
--
ALTER TABLE `ref_event_type`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_interface`
--
ALTER TABLE `ref_interface`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_interface_category`
--
ALTER TABLE `ref_interface_category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_statss_status`
--
ALTER TABLE `ref_statss_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_system`
--
ALTER TABLE `ref_system`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_waitactions`
--
ALTER TABLE `ref_waitactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_works`
--
ALTER TABLE `ref_works`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `ref_work_status`
--
ALTER TABLE `ref_work_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `repairs`
--
ALTER TABLE `repairs`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `statss`
--
ALTER TABLE `statss`
  MODIFY `id` int(10) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `stats_ap`
--
ALTER TABLE `stats_ap`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `stats_fail_auto_tmp`
--
ALTER TABLE `stats_fail_auto_tmp`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `stats_lte`
--
ALTER TABLE `stats_lte`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `stats_ping`
--
ALTER TABLE `stats_ping`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `stats_status`
--
ALTER TABLE `stats_status`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `stats_status_settings_modular`
--
ALTER TABLE `stats_status_settings_modular`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `usergroups`
--
ALTER TABLE `usergroups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `wifi_log`
--
ALTER TABLE `wifi_log`
  MODIFY `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `wifi_stat_equipment`
--
ALTER TABLE `wifi_stat_equipment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `wifi_stat_map`
--
ALTER TABLE `wifi_stat_map`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `wifi_stat_map_data`
--
ALTER TABLE `wifi_stat_map_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `wifi_stat_map_sectors`
--
ALTER TABLE `wifi_stat_map_sectors`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `workers`
--
ALTER TABLE `workers`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `workexecution`
--
ALTER TABLE `workexecution`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `workexecution_workers`
--
ALTER TABLE `workexecution_workers`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `stats_status`
--
ALTER TABLE `stats_status`
  ADD CONSTRAINT `stats_status_ibfk_1` FOREIGN KEY (`id_equipment`) REFERENCES `equipment` (`id`),
  ADD CONSTRAINT `stats_status_ibfk_2` FOREIGN KEY (`status`) REFERENCES `ref_statss_status` (`id`);

--
-- Ограничения внешнего ключа таблицы `wifi_stat_map_log`
--
ALTER TABLE `wifi_stat_map_log`
  ADD CONSTRAINT `wifi_stat_map_log_ibfk_1` FOREIGN KEY (`map_id`) REFERENCES `wifi_stat_map` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `wifi_stat_map_log_ibfk_2` FOREIGN KEY (`id_equipment`) REFERENCES `equipment` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `wifi_stat_map_sectors`
--
ALTER TABLE `wifi_stat_map_sectors`
  ADD CONSTRAINT `map_id` FOREIGN KEY (`map_id`) REFERENCES `wifi_stat_map` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
SET FOREIGN_KEY_CHECKS=1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
