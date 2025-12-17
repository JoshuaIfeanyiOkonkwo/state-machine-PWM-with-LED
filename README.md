# **Finite-State Machine (FSM) for PWM‑Controlled LEDs Using Buttons on Zedboard**

This project implements a finite‑state machine (FSM) that controls the PWM outputs of three LEDs.  
Each state corresponds to a specific set of PWM duty cycles (0–255), where:

- **0** → LED fully OFF  
- **255** → LED fully ON  
- **128** → LED dimmed  
- PWM module reused from Exercise 3  

The FSM runs on a configurable timer and supports an **asynchronous alarm mode** that overrides normal operation.

---

## **LED Output States**

The FSM contains nine functional states, each defining a unique PWM pattern for the three LEDs:

| **State Name** | **LED1 PWM** | **LED2 PWM** | **LED3 PWM** |
|----------------|--------------|--------------|--------------|
| State 1        | 255          | 0            | 0            |
| State 2        | 0            | 255          | 0            |
| State 3        | 0            | 0            | 255          |
| State 4        | 255          | 255          | 255          |
| State 5        | 255          | 255          | 0            |
| State 6        | 0            | 255          | 255          |
| State 7        | 128          | 0            | 128          |
| State Reset    | 0            | 0            | 0            |
| State Alarm (*)| 255/0        | 255/0        | 255/0        |

**(*) Alarm State:**  
- Lasts for **80 timer clock rising edges**  
- LEDs alternate between **255 and 0**  
- Blink rate is **10× faster** than the current speed mode  

---

## **Speed Mode Configuration**

The FSM state duration depends on a 2‑bit input `speed_in`:

| **speed_in** | **State Duration (Timer Clock Cycles)** | **Simulation (100 ns)** | **Zedboard (100 ms)** |
|--------------|------------------------------------------|---------------------------|-------------------------|
| `00` (default) | 10  | 10 × 100 ns | 10 × 100 ms |
| `01`          | 30  | 30 × 100 ns | 30 × 100 ms |
| `10`          | 50  | 50 × 100 ns | 50 × 100 ms |
| `11`          | 70  | 70 × 100 ns | 70 × 100 ms |

---

## **Alarm Mode (Asynchronous Input)**

The FSM includes an asynchronous **alarm** input that forces the system into **State Alarm**:

### **Alarm Behavior**
- Triggered on the **falling edge** of the alarm signal  
- Lasts for **80 rising edges** of the main timer  
- LEDs blink ON/OFF at **10× the speed** of the current FSM mode  
- Implemented using two internal timers:
  - **Timer 1 (100 ms)** → Controls state duration  
  - **Timer 2 (10× faster)** → Controls LED blinking  
- Alarm mode can be **interrupted by reset**  
- After alarm completes, FSM transitions to **State 4**

---

## **Timers Used**

### **Timer 1 — State Duration Timer**
- Generates a **10 Hz clock** (100 ms period)
- Controls how long each state lasts
- Duration scales with `speed_in`

### **Timer 2 — Alarm Blink Timer**
- Runs at **10× the frequency** of Timer 1
- Toggles LED PWM between 0 and 255 during alarm mode

---

## **Testbench Requirements**

A testbench must verify:

- Normal state transitions  
- PWM output correctness  
- Speed mode timing  
- Alarm activation and duration  
- Alarm blinking at 10× speed  
- Reset behavior during alarm  

The same testbench structure from **Exercise 3** can be reused with additional alarm test cases.

---

## **Zedboard Implementation**

The system is implemented on a **Zedboard**, using:

- **Buttons** → State control, reset, alarm  
- **LEDs** → PWM‑controlled outputs  
- **PWM module** → Reused from Exercise 3  
- **Timer module** → Generates 10 Hz clock for state timing  

The FSM cycles through states based on `speed_in`, and the alarm overrides normal operation with high‑speed blinking.

---

## **Project Summary**

This project demonstrates:

- FSM design for multi‑LED PWM control  
- Multi‑rate timing using dual timers  
- Asynchronous event handling (alarm)  
- Hardware implementation on Zedboard  
- Verification through simulation and testbenching  

It provides a complete example of combining **digital design**, **PWM control**, **timing logic**, and **hardware integration**.

