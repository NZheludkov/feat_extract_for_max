#!/bin/bash

# =============================================================================
# create_dataset.sh – извлечение признаков (features) из результатов прогона
# =============================================================================

# Значения по умолчанию
pdk_path=""
rtl_dataset_path=""
design=""
run_dir=""
output_dir=""
extract_script="./extract_feats_route.tcl"   # ваш скрипт сбора данных
verbose=0

# Функция справки
show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ]

Обязательные опции:
    --pdk_path PATH              Путь к PDK
    --rtl_dataset_path PATH      Путь к RTL датасету (может не использоваться)
    --design NAME                Имя дизайна (блока)
    --run_dir DIR                Директория с результатами запуска (содержит .odb, .sdc и т.д.)
    --output_dir DIR             Директория, куда будут сохранены извлечённые признаки

Дополнительные опции:
    --extract_script PATH        Tcl-скрипт для OpenROAD (по умолчанию: ./flow_scripts/extract_features.tcl)
    --verbose, -v                Подробный вывод
    --help, -h                   Показать эту справку

Пример:
    $0 --pdk_path ./PDK --rtl_dataset_path ./data --design sasc_top --run_dir ./runs/sasc_top/20260517_120000 --output_dir ./features
EOF
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --pdk_path)          pdk_path="$2"; shift 2 ;;
        --rtl_dataset_path)  rtl_dataset_path="$2"; shift 2 ;;
        --design)            design="$2"; shift 2 ;;
        --run_dir)           run_dir="$2"; shift 2 ;;
        --output_dir)        output_dir="$2"; shift 2 ;;
        --extract_script)    extract_script="$2"; shift 2 ;;
        --verbose|-v)        verbose=1; shift ;;
        --help|-h)           show_help; exit 0 ;;
        *) echo "Ошибка: Неизвестная опция $1"; show_help; exit 1 ;;
    esac
done

# Проверка обязательных параметров
if [[ -z "$pdk_path" || -z "$rtl_dataset_path" || -z "$design" || -z "$run_dir" || -z "$output_dir" ]]; then
    echo "Ошибка: Не все обязательные параметры заданы."
    show_help
    exit 1
fi

# Проверка существования run_dir
if [[ ! -d "$run_dir" ]]; then
    echo "Ошибка: Директория с результатами '$run_dir' не существует."
    exit 1
fi

# Проверка существования скрипта извлечения
if [[ ! -f "$extract_script" ]]; then
    echo "Ошибка: Скрипт извлечения признаков '$extract_script' не найден."
    exit 1
fi

# Создание выходной директории
mkdir -p "$output_dir"

# Вывод информации (verbose)
if [[ $verbose -eq 1 ]]; then
    echo "=== Параметры извлечения признаков ==="
    echo "PDK путь:            $pdk_path"
    echo "RTL датасет:         $rtl_dataset_path"
    echo "Дизайн:              $design"
    echo "Директория запуска:  $run_dir"
    echo "Выходная директория: $output_dir"
    echo "Скрипт извлечения:   $extract_script"
    echo "====================================="
fi

# =========================
# PDK configuration
# =========================

if [[ "$pdk_path" =~ freepdk45 ]]; then

    tech_lef="${pdk_path}/base/apr/freepdk45.tech.lef"
    cells_lef="${pdk_path}/libs/nangate45/lef/NangateOpenCellLibrary.macro.mod.lef"
    lef_list="${tech_lef} ${cells_lef}"

    liberty="${pdk_path}/libs/nangate45/nldm/NangateOpenCellLibrary_typical.lib"

    core_site="FreePDK45_38x28_10R_NP_162NW_34O"

    tap_cell="TAPCELL_X1"
    endcap_cell="TAPCELL_X1"
    tap_cell_distance="120"

    techmap_verilog_files=$(echo ${pdk_path}/libs/nangate45/techmap/yosys/*)

    bottom_routing_metal="metal1"
    top_routing_metal="metal10"

    pins_hor_layers="metal3 metal5"
    pins_ver_layers="metal2 metal4"

    wire_rc_metal="metal3"

    tiehi_cell="LOGIC1_X1"
    tielo_cell="LOGIC0_X1"

    tiehi_cell_pin="Z"
    tielo_cell_pin="Z"

    filler_cells="FILLCELL_X1 FILLCELL_X2 FILLCELL_X4 FILLCELL_X8 FILLCELL_X16 FILLCELL_X32"

    dont_use_cells="ANTENNA_X1 FILL* LOGIC* TAPCELL_X1 TBUF* TINV* TLAT*"

    max_slew_cts="0.5"
    max_cap_cts="0.3"

    cts_root_buf="CLKBUF_X3"
    cts_buf_list="CLKBUF_X1 CLKBUF_X2 CLKBUF_X3"

    process_node="45"

    rc_extract_file="${pdk_path}/base/pex/openroad/typical.rules"

    pdk_name="freepdk45"
    echo aaaa

    # =========================
    # Default flow parameters
    # =========================

    : ${CLK_PERIOD:=100.0}
    : ${IO_DELAY:=0.33}
    : ${CU:=20}
    : ${AR:=1.0}

    : ${PDN_HWIDTH:=1.6}
    : ${PDN_HSPACING:=1.6}
    : ${PDN_HPITCH:=16}

    : ${PDN_VWIDTH:=1.6}
    : ${PDN_VSPACING:=1.6}
    : ${PDN_VPITCH:=16}

elif [[ "$pdk_path" =~ gf180 ]]; then

    tech_lef="${pdk_path}/base/apr/gf180mcu_6LM_1TM_9K_9t_tech.lef"
    cells_lef="${pdk_path}/libs/gf180mcu_fd_sc_mcu9t5v0/lef/gf180mcu_fd_sc_mcu9t5v0.lef"
    lef_list="${tech_lef} ${cells_lef}"

    liberty="${pdk_path}/libs/gf180mcu_fd_sc_mcu9t5v0/nldm/gf180mcu_fd_sc_mcu9t5v0__ss_125C_4v50.lib.gz"

    core_site="GF018hv5v_green_sc9"

    tap_cell="gf180mcu_fd_sc_mcu9t5v0__filltie"
    endcap_cell="gf180mcu_fd_sc_mcu9t5v0__endcap"

    tap_cell_distance="25"

    techmap_verilog_files=$(echo ${pdk_path}/libs/gf180mcu_fd_sc_mcu9t5v0/techmap/yosys/*)

    bottom_routing_metal="Metal1"
    top_routing_metal="MetalTop"

    pins_hor_layers="Metal3 Metal5"
    pins_ver_layers="Metal2 Metal4"

    wire_rc_metal="Metal3"

    tiehi_cell="gf180mcu_fd_sc_mcu9t5v0__tieh"
    tielo_cell="gf180mcu_fd_sc_mcu9t5v0__tiel"

    tiehi_cell_pin="Z"
    tielo_cell_pin="ZN"

    filler_cells="gf180mcu_fd_sc_mcu9t5v0__fillcap_64 \
gf180mcu_fd_sc_mcu9t5v0__fillcap_32 \
gf180mcu_fd_sc_mcu9t5v0__fillcap_16 \
gf180mcu_fd_sc_mcu9t5v0__fillcap_8 \
gf180mcu_fd_sc_mcu9t5v0__fillcap_4 \
gf180mcu_fd_sc_mcu9t5v0__fill_1 \
gf180mcu_fd_sc_mcu9t5v0__fill_2"

    dont_use_cells="gf180mcu_fd_sc_mcu9t5v0__antenna \
gf180mcu_fd_sc_mcu9t5v0__clk* \
gf180mcu_fd_sc_mcu9t5v0__endcap \
gf180mcu_fd_sc_mcu9t5v0__fill* \
gf180mcu_fd_sc_mcu9t5v0__lat* \
gf180mcu_fd_sc_mcu9t5v0__tie*"

    max_slew_cts="0.5"
    max_cap_cts="0.3"

    cts_root_buf="gf180mcu_fd_sc_mcu9t5v0__clkinv_16"

    cts_buf_list="gf180mcu_fd_sc_mcu9t5v0__clkinv_1 \
gf180mcu_fd_sc_mcu9t5v0__clkinv_2 \
gf180mcu_fd_sc_mcu9t5v0__clkinv_4 \
gf180mcu_fd_sc_mcu9t5v0__clkinv_8 \
gf180mcu_fd_sc_mcu9t5v0__clkinv_16"

    process_node="180"

    rc_extract_file="${pdk_path}/base/pex/openroad/gf180mcu_1p6m_1tm_9k_sp_smim_OPTB_wst.rules"

    pdk_name="gf180"

    # =========================
    # Default flow parameters
    # =========================

    : ${CLK_PERIOD:=100.0}
    : ${IO_DELAY:=0.33}
    : ${CU:=20}
    : ${AR:=1.0}

    : ${PDN_HWIDTH:=4.4}
    : ${PDN_HSPACING:=4.4}
    : ${PDN_HPITCH:=44}

    : ${PDN_VWIDTH:=4.4}
    : ${PDN_VSPACING:=4.4}
    : ${PDN_VPITCH:=44}

else
    echo "ERROR: Unsupported PDK: $pdk_path"
    exit 1
fi

# =========================
# Export all variables
# =========================

export pdk_path
export rtl_dataset_path
export design
export output_dir
export verbose

export tech_lef
export cells_lef
export lef_list
export liberty

export core_site

export tap_cell
export endcap_cell
export tap_cell_distance

export techmap_verilog_files

export bottom_routing_metal
export top_routing_metal

export pins_hor_layers
export pins_ver_layers

export wire_rc_metal

export tiehi_cell
export tielo_cell

export tiehi_cell_pin
export tielo_cell_pin

export filler_cells
export dont_use_cells

export max_slew_cts
export max_cap_cts

export cts_root_buf
export cts_buf_list

export process_node

export rc_extract_file

export pdk_name

export CLK_PERIOD
export IO_DELAY
export CU
export AR

export PDN_HWIDTH
export PDN_HSPACING
export PDN_HPITCH

export PDN_VWIDTH
export PDN_VSPACING
export PDN_VPITCH

# Экспорт всех переменных в окружение (нужны в Tcl-скриптах)
export pdk_path
export rtl_dataset_path
export design
export run_dir
export output_dir

# Можно также экспортировать путь к скрипту, если он используется в Tcl
export extract_script

# Запуск OpenROAD в batch-режиме (без GUI) с вашим скриптом сбора данных
echo "Запуск OpenROAD для извлечения признаков..."
openroad -exit -threads 4 "./extract_feats_floorplan.tcl"
openroad -exit -threads 4 "./extract_feats_prects.tcl"
openroad -exit -threads 4 "./extract_feats_route.tcl"

echo "Извлечение признаков завершено. Результаты в: $output_dir"
exit 0