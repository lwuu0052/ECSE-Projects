/* USER CODE BEGIN Header */
/**
  **************************
  * @file           : main.c
  * @brief          : Main program body
  **************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  **************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define FILTER_SIZE 4
#define RX_BUF_SIZE 64
#define OUTLIER_THRESHOLD 800 // Tunable distance
#define SAMPLES_PER_BLOCK 1500
#define SPI_BUF_SIZE (SAMPLES_PER_BLOCK * 2)
#define DISTANCE_TIMEOUT 600
#define RECORDING_LINGER_TIME 100
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
SPI_HandleTypeDef hspi1;
DMA_HandleTypeDef hdma_spi1_rx;

TIM_HandleTypeDef htim1;
TIM_HandleTypeDef htim6;
TIM_HandleTypeDef htim7;
TIM_HandleTypeDef htim16;

UART_HandleTypeDef huart2;
DMA_HandleTypeDef hdma_usart2_rx;
DMA_HandleTypeDef hdma_usart2_tx;

/* USER CODE BEGIN PV */
uint16_t filter_buffer[FILTER_SIZE] = {2048, 2048, 2048, 2048};
int filter_index = 0;
uint32_t running_sum = 2048 * FILTER_SIZE; // So the filter size can be variable

uint8_t spi_dma_buffer[SPI_BUF_SIZE * 2];
uint8_t rx_dma_buffer[RX_BUF_SIZE];
char cmd_processing_buffer[RX_BUF_SIZE];

// State Machine Variables
uint8_t current_mode = 0; // 'm' for manual, 'd' for distance, 0 for idle
uint8_t is_recording = 0;
uint8_t light_on = 0;
uint16_t manual_seconds_target = 0;
uint16_t seconds_elapsed = 0;
uint16_t distance_threshold_cm = 10; // Default to 10cm
uint32_t last_distance_update = 0;
uint32_t departure_time = 0;
uint8_t stop_sent = 0;
uint8_t start = 0;

// Ultrasonic Sensor Variables
uint32_t ic_val1 = 0;
uint32_t ic_val2 = 0;
uint8_t is_first_captured = 0;
volatile float distance_cm = 999.0;

uint8_t processed_uart_buffer_A[SPI_BUF_SIZE];
uint8_t processed_uart_buffer_B[SPI_BUF_SIZE];
uint8_t tx_toggle = 0;
volatile uint8_t spi_data_ready = 0;
uint8_t *ptr_to_process = NULL;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_SPI1_Init(void);
static void MX_TIM1_Init(void);
static void MX_TIM6_Init(void);
static void MX_TIM7_Init(void);
static void MX_TIM16_Init(void);
/* USER CODE BEGIN PFP */
void delay_uS(uint16_t delay);
void Process_And_Send(uint8_t *data_ptr);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
void UART2_ResetReception(void)
{
    // Stop current DMA reception
    HAL_UART_AbortReceive(&huart2);

    // Clear UART error flags (noise from cable switching)
    __HAL_UART_CLEAR_FLAG(&huart2, UART_CLEAR_OREF | UART_CLEAR_NEF | UART_CLEAR_FEF);

    // Restart DMA reception
    HAL_UARTEx_ReceiveToIdle_DMA(&huart2, rx_dma_buffer, RX_BUF_SIZE);
    __HAL_DMA_DISABLE_IT(huart2.hdmarx, DMA_IT_HT);
}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_USART2_UART_Init();
  MX_SPI1_Init();
  MX_TIM1_Init();
  MX_TIM6_Init();
  MX_TIM7_Init();
  MX_TIM16_Init();
  /* USER CODE BEGIN 2 */
  UART2_ResetReception();

  // Start listening for SPI data from the Sampling STM
  HAL_SPI_Receive_DMA(&hspi1, spi_dma_buffer, SPI_BUF_SIZE * 2);

  // Start the Ultrasonic Echo Input Capture
  HAL_TIM_IC_Start_IT(&htim1, TIM_CHANNEL_1);

  // Start the Ultrasonic Trigger generation timer
  HAL_TIM_Base_Start_IT(&htim6);
  HAL_TIM_Base_Start_IT(&htim16);
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
	  if (spi_data_ready) {
		  spi_data_ready = 0;
		  Process_And_Send(ptr_to_process);
	  }
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  if (HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1) != HAL_OK)
  {
    Error_Handler();
  }
  /** Configure LSE Drive Capability
  */
  HAL_PWR_EnableBkUpAccess();
  __HAL_RCC_LSEDRIVE_CONFIG(RCC_LSEDRIVE_LOW);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_LSE|RCC_OSCILLATORTYPE_MSI;
  RCC_OscInitStruct.LSEState = RCC_LSE_ON;
  RCC_OscInitStruct.MSIState = RCC_MSI_ON;
  RCC_OscInitStruct.MSICalibrationValue = 0;
  RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_6;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_MSI;
  RCC_OscInitStruct.PLL.PLLM = 1;
  RCC_OscInitStruct.PLL.PLLN = 40;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV7;
  RCC_OscInitStruct.PLL.PLLQ = RCC_PLLQ_DIV2;
  RCC_OscInitStruct.PLL.PLLR = RCC_PLLR_DIV2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    Error_Handler();
  }
  /** Enable MSI Auto calibration
  */
  HAL_RCCEx_EnableMSIPLLMode();
}

/**
  * @brief SPI1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_SPI1_Init(void)
{

  /* USER CODE BEGIN SPI1_Init 0 */

  /* USER CODE END SPI1_Init 0 */

  /* USER CODE BEGIN SPI1_Init 1 */

  /* USER CODE END SPI1_Init 1 */
  /* SPI1 parameter configuration*/
  hspi1.Instance = SPI1;
  hspi1.Init.Mode = SPI_MODE_SLAVE;
  hspi1.Init.Direction = SPI_DIRECTION_2LINES_RXONLY;
  hspi1.Init.DataSize = SPI_DATASIZE_8BIT;
  hspi1.Init.CLKPolarity = SPI_POLARITY_LOW;
  hspi1.Init.CLKPhase = SPI_PHASE_1EDGE;
  hspi1.Init.NSS = SPI_NSS_SOFT;
  hspi1.Init.FirstBit = SPI_FIRSTBIT_MSB;
  hspi1.Init.TIMode = SPI_TIMODE_DISABLE;
  hspi1.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;
  hspi1.Init.CRCPolynomial = 7;
  hspi1.Init.CRCLength = SPI_CRC_LENGTH_DATASIZE;
  hspi1.Init.NSSPMode = SPI_NSS_PULSE_DISABLE;
  if (HAL_SPI_Init(&hspi1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN SPI1_Init 2 */

  /* USER CODE END SPI1_Init 2 */

}

/**
  * @brief TIM1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM1_Init(void)
{

  /* USER CODE BEGIN TIM1_Init 0 */

  /* USER CODE END TIM1_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_IC_InitTypeDef sConfigIC = {0};

  /* USER CODE BEGIN TIM1_Init 1 */

  /* USER CODE END TIM1_Init 1 */
  htim1.Instance = TIM1;
  htim1.Init.Prescaler = 64-1;
  htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim1.Init.Period = 65535;
  htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim1.Init.RepetitionCounter = 0;
  htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim1) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim1, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_TIM_IC_Init(&htim1) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterOutputTrigger2 = TIM_TRGO2_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim1, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sConfigIC.ICPolarity = TIM_INPUTCHANNELPOLARITY_BOTHEDGE;
  sConfigIC.ICSelection = TIM_ICSELECTION_DIRECTTI;
  sConfigIC.ICPrescaler = TIM_ICPSC_DIV1;
  sConfigIC.ICFilter = 0;
  if (HAL_TIM_IC_ConfigChannel(&htim1, &sConfigIC, TIM_CHANNEL_1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM1_Init 2 */

  /* USER CODE END TIM1_Init 2 */
}

/**
  * @brief TIM6 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM6_Init(void)
{

  /* USER CODE BEGIN TIM6_Init 0 */

  /* USER CODE END TIM6_Init 0 */

  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM6_Init 1 */

  /* USER CODE END TIM6_Init 1 */
  htim6.Instance = TIM6;
  htim6.Init.Prescaler = 80-1;
  htim6.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim6.Init.Period = 65535;
  htim6.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim6) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim6, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM6_Init 2 */

  /* USER CODE END TIM6_Init 2 */

}

/**
  * @brief TIM7 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM7_Init(void)
{

  /* USER CODE BEGIN TIM7_Init 0 */

  /* USER CODE END TIM7_Init 0 */

  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM7_Init 1 */

  /* USER CODE END TIM7_Init 1 */
  htim7.Instance = TIM7;
  htim7.Init.Prescaler = 8000-1;
  htim7.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim7.Init.Period = 10000-1;
  htim7.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim7) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim7, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM7_Init 2 */

  /* USER CODE END TIM7_Init 2 */

}

/**
  * @brief TIM16 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM16_Init(void)
{

  /* USER CODE BEGIN TIM16_Init 0 */

  /* USER CODE END TIM16_Init 0 */

  /* USER CODE BEGIN TIM16_Init 1 */

  /* USER CODE END TIM16_Init 1 */
  htim16.Instance = TIM16;
  htim16.Init.Prescaler = 80-1;
  htim16.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim16.Init.Period = 65535;
  htim16.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim16.Init.RepetitionCounter = 0;
  htim16.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim16) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM16_Init 2 */

  /* USER CODE END TIM16_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 921600;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_8;
  huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void)
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA1_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA1_Channel2_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Channel2_IRQn, 1, 0);
  HAL_NVIC_EnableIRQ(DMA1_Channel2_IRQn);
  /* DMA1_Channel6_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Channel6_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(DMA1_Channel6_IRQn);
  /* DMA1_Channel7_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Channel7_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(DMA1_Channel7_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD3_GPIO_Port, LD3_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : PA6 */
  GPIO_InitStruct.Pin = GPIO_PIN_6;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pin : LD3_Pin */
  GPIO_InitStruct.Pin = LD3_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD3_GPIO_Port, &GPIO_InitStruct);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */
void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t Size)
{
	if (huart->Instance == USART2) {
		// Null-terminate the string received via DMA
		rx_dma_buffer[Size] = '\0';
		memcpy(cmd_processing_buffer, rx_dma_buffer, Size + 1);

		char mode = cmd_processing_buffer[0];
		int value = atoi(&cmd_processing_buffer[1]);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_3, GPIO_PIN_RESET);

        if (mode == 'm') {
            current_mode = 'm';
            manual_seconds_target = (uint16_t)value;
            seconds_elapsed = 0;
            is_recording = 1;
            HAL_TIM_Base_Start_IT(&htim7); // Start the 1-second timer
        }
        else if (mode == 'd') {
            current_mode = 'd';
            is_recording = 1;
            distance_threshold_cm = (uint16_t)value;
            if(distance_threshold_cm == 0) distance_threshold_cm = 10;
            departure_time = HAL_GetTick();
			stop_sent = 1;
			start = 0;
        }

        // Listen for the next command
        HAL_UARTEx_ReceiveToIdle_DMA(&huart2, rx_dma_buffer, RX_BUF_SIZE);
        __HAL_DMA_DISABLE_IT(huart2.hdmarx, DMA_IT_HT);
    }
}

// Half-Buffer Callback (Ping)
void HAL_SPI_RxHalfCpltCallback(SPI_HandleTypeDef *hspi) {
    ptr_to_process = &spi_dma_buffer[0];
    spi_data_ready = 1;
}

void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi) {
    ptr_to_process = &spi_dma_buffer[SPI_BUF_SIZE];
    spi_data_ready = 1;
}

void Process_And_Send(uint8_t *data_ptr) {

	// Write into current toggle's buffer
	uint8_t *active_buf = (tx_toggle == 0) ? processed_uart_buffer_A : processed_uart_buffer_B;

    uint32_t current_time = HAL_GetTick();
	// Assuming distance_cm updates periodically; we use a timeout to know if it's stale
	uint8_t is_distance_valid = (current_time - last_distance_update) < DISTANCE_TIMEOUT;

    // Conditional Transmission
    if (is_recording) {
    	for (int i = 0; i < SAMPLES_PER_BLOCK; i++) {
    	        // Extract 12-bit sample from Sampling STM32
    	        uint16_t raw_sample = (data_ptr[i*2 + 1] << 8) | data_ptr[i*2];

    	        // Filter Logic
    	        uint16_t current_mean = (uint16_t)(running_sum / FILTER_SIZE);
    	        int16_t diff = (int16_t)raw_sample - (int16_t)current_mean;
    	        if (diff > OUTLIER_THRESHOLD || diff < -OUTLIER_THRESHOLD) {
    	            raw_sample = current_mean;
    	        }

    	        running_sum -= filter_buffer[filter_index];
    	        filter_buffer[filter_index] = raw_sample;
    	        running_sum += filter_buffer[filter_index];
    	        filter_index = (filter_index + 1) % FILTER_SIZE;
    	        uint16_t filtered = (uint16_t)(running_sum / FILTER_SIZE);

    	        active_buf[(i*2) + 1] = (uint8_t)(filtered >> 8);
    	        active_buf[(i*2)]     = (uint8_t)(filtered & 0xFF);
    	    }

		if (current_mode == 'm') {
			if (light_on == 0) {
				HAL_GPIO_WritePin(GPIOB, GPIO_PIN_3, GPIO_PIN_SET);
				light_on = 1;
			}
			HAL_UART_Transmit_DMA(&huart2, active_buf, SPI_BUF_SIZE);
			tx_toggle = !tx_toggle;
		}
		else if (current_mode == 'd') {
			uint8_t object_in_range = (is_distance_valid && distance_cm <= (float)distance_threshold_cm);
			// Only transmit if user is within distance threshold
			if (object_in_range) {
				departure_time = HAL_GetTick(); // Keep resetting the timer while object is present
				stop_sent = 0;                  // Ready to handle the next departure
			}

			// Transmit if object is present OR we are within the 0.1 second linger window
			if (object_in_range || (HAL_GetTick() - departure_time < RECORDING_LINGER_TIME)) {
				if (!start){
					start = 1;
					HAL_GPIO_WritePin(GPIOB, GPIO_PIN_3, GPIO_PIN_SET);
				} else {
					HAL_UART_Transmit_DMA(&huart2, active_buf, SPI_BUF_SIZE);
					tx_toggle = !tx_toggle;
				}
			}
			else {
				if (!stop_sent) {
					HAL_GPIO_WritePin(GPIOB, GPIO_PIN_3, GPIO_PIN_RESET); // LED OFF
					stop_sent = 1;
					start = 0;

					// Reset filter for next transmission
					running_sum = 2048 * FILTER_SIZE;
					for (int i = 0; i < FILTER_SIZE; i++) filter_buffer[i] = 2048;
					filter_index = 0;
				}
			}
		}
	}
    else if (light_on) {
		light_on = 0;
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_3, GPIO_PIN_RESET);
	}
}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
    // Manual Mode Duration Timer (1 Hz)
    if (htim->Instance == TIM7) {
        if (current_mode == 'm' && is_recording) {
            seconds_elapsed++;
            if (seconds_elapsed >= manual_seconds_target) {
                is_recording = 0; // Stop recording
                HAL_TIM_Base_Stop_IT(&htim7);
            }
        }
    }

    // Ultrasonic Trigger Timer (Every ~60ms)
    if (htim->Instance == TIM6) {
        // Send a 10us HIGH pulse to the TRIG pin
        HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_SET);
        // Delay 10us (Requires a small blocking delay or another timer,
        delay_uS(10);
        HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);
    }
}

// ULTRASONIC ECHO INPUT CAPTURE
void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim) {
    if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_1) {
        if (is_first_captured == 0) {
            ic_val1 = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_1);
            is_first_captured = 1;
            __HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_1, TIM_INPUTCHANNELPOLARITY_FALLING);
        } else {
            ic_val2 = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_1);
            __HAL_TIM_SET_COUNTER(htim, 0);

            uint32_t difference = (ic_val2 > ic_val1) ? (ic_val2 - ic_val1) : ((0xFFFF - ic_val1) + ic_val2);

            // Calculate distance in cm (depends on your timer clock frequency)
            // Assuming 1us timer tick: distance = (time * 0.0343) / 2
            distance_cm = difference * 0.01715;
            last_distance_update = HAL_GetTick();

            is_first_captured = 0;
            __HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_1, TIM_INPUTCHANNELPOLARITY_RISING);
        }
    }
}

void delay_uS(uint16_t delay)
{
	__HAL_TIM_SET_COUNTER(&htim16, 0);
	while(__HAL_TIM_GET_COUNTER(&htim16) < delay)
	{

	}
}

void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart)
{
	// When there is noise and the idle line interrupt fails resets the receiver
    if (huart->Instance == USART2)
	{
		UART2_ResetReception();
	}
}

void HAL_SPI_ErrorCallback(SPI_HandleTypeDef *hspi) {
    if (hspi->Instance == SPI1) {
        // Check if it was an Overrun error
        if (HAL_SPI_GetError(hspi) & HAL_SPI_ERROR_OVR) {
            // Clear the OVR flag by reading DR and SR (HAL does this in Abort)
            HAL_SPI_Abort(hspi);

            // Restart the DMA
            HAL_SPI_Receive_DMA(&hspi1, spi_dma_buffer, SPI_BUF_SIZE * 2);
        }
    }
}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
