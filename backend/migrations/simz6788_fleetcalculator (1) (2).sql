-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 09, 2026 at 06:47 PM
-- Server version: 11.4.10-MariaDB-cll-lve
-- PHP Version: 8.4.20

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `simz6788_fleetcalculator`
--

-- --------------------------------------------------------

--
-- Table structure for table `calculations`
--

CREATE TABLE `calculations` (
  `id` varchar(36) NOT NULL,
  `user_id` int(11) NOT NULL,
  `user_nrp` varchar(50) DEFAULT NULL,
  `material` varchar(10) NOT NULL,
  `distance` double NOT NULL,
  `actual_hauler` int(11) NOT NULL,
  `loader_prod` double NOT NULL,
  `loader_name` varchar(255) NOT NULL,
  `hauler_cap` double NOT NULL,
  `hauler_name` varchar(255) NOT NULL,
  `loading_speed` double NOT NULL DEFAULT 19,
  `speed` double NOT NULL,
  `loading_time` double NOT NULL,
  `spotting_time` double NOT NULL DEFAULT 0,
  `dumping_time` double NOT NULL,
  `cycle_time` double NOT NULL,
  `recommended_hauler` int(11) NOT NULL,
  `match_factor` double NOT NULL,
  `status` varchar(50) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `nrp` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nrp`, `name`, `email`, `created_at`) VALUES
(1, '26000218', 'Gustian Aryasatya', 'admin@fleet.com', '2026-05-04 11:51:42'),
(3, '26000418', 'Testing', 'testing@gmail.com', '2026-05-05 03:08:08');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `calculations`
--
ALTER TABLE `calculations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_timestamp` (`user_id`,`timestamp`),
  ADD KEY `idx_user_nrp` (`user_nrp`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nrp` (`nrp`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `calculations`
--
ALTER TABLE `calculations`
  ADD CONSTRAINT `calculations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
