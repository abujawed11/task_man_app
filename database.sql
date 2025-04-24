-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 24, 2025 at 12:46 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `task_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` varchar(255) NOT NULL,
  `username` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `role` varchar(100) DEFAULT NULL,
  `fcm_token` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `phone`, `password`, `role`, `fcm_token`) VALUES
('1bca0b8a-7e6c-4e5b-bd76-77ebb1378911', 'admin', 'admin@mail', '7834908347', '1234', 'Member', 'dX1Fr3UnRVavOkIEVZHcgE:APA91bH3YIDagY1ksXt9vsve9aKwg0m6javYjBHO50Yqchji-vzPoFHCeDlSmu_paTstSISceHkdEo_rAvFo7bfQIX0yVLaSZ0XG3qJMrobDVDhwVC9m4Uw'),
('320b8859-2629-4f01-9572-26a33209a9a5', 'srinivas', 'sri@mail', '348987655', '1234', 'Team Leader', 'fTOrOjpKTAicI3v7q0l1yU:APA91bEeZ4leZipO6FoCU07U9Mq8BIdaiEk1QqFvPwdGtVTDhPr1_lWl4bEOKUY2FoXLL7KDM7NXn1_SIRLH7FALEQxAdKQ561ohZeY7DoT61lOvje-tJlI'),
('3a80a142-5bcb-43c8-8821-6e21e5504405', 'ayaansunrack@gmail.com', 'ayaan@test.com', '9999999999', 'ayaan123', 'admin', 'optional-token-here'),
('974ac42c-70f8-48ad-b524-c24b2088792f', 'abujawed11', 'ayaan@test.com', '9999999999', '1234', 'admin', 'optional-token-here'),
('c8617270-5a5c-4bec-bb58-de4b462bf1f8', 'ayan', 'ayan@gmail', '12345678', '1234', 'Member', 'fTOrOjpKTAicI3v7q0l1yU:APA91bEeZ4leZipO6FoCU07U9Mq8BIdaiEk1QqFvPwdGtVTDhPr1_lWl4bEOKUY2FoXLL7KDM7NXn1_SIRLH7FALEQxAdKQ561ohZeY7DoT61lOvje-tJlI'),
('d0a9fc03-6367-45a7-a8a0-683f6a635ac9', 'azim', 'azim@mail', '7893445345', '1234', 'Admin', 'fTOrOjpKTAicI3v7q0l1yU:APA91bEeZ4leZipO6FoCU07U9Mq8BIdaiEk1QqFvPwdGtVTDhPr1_lWl4bEOKUY2FoXLL7KDM7NXn1_SIRLH7FALEQxAdKQ561ohZeY7DoT61lOvje-tJlI'),
('ff0f21c3-eecd-4040-a497-e4f5808e3734', 'abujawed12', 'ayaan@test.com', '9999999999', '1234', 'admin', 'optional-token-here');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
