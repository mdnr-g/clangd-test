#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/dma.h>

static void dma_setup(void) {
    dma_disable_stream(DMA1, DMA1_S5CR);
}
static void gpio_setup(void) {
    rcc_periph_clock_enable(RCC_GPIOD);

    gpio_mode_setup(GPIOD, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO14);
}

int main(void) {
    int i;

    gpio_setup();
    dma_setup();

    while (1) {
        gpio_toggle(GPIOD, GPIO14);     /* LED on/off */
        for (i = 0; i < 1000000; i++) { /* Wait a bit. */
            __asm__("nop");
        }
    }

    return 0;
}
