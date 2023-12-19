#!/bin/bash

# 비교 대상 디렉토리 경로 설정
dir1="./my_result"
dir2="./testresult"

# 두 디렉토리에 있는 파일 목록을 얻어옵니다.
files1=($(ls "$dir1"))
files2=($(ls "$dir2"))

# 두 디렉토리에 공통으로 존재하는 파일들을 찾습니다.
common_files=($(comm -12 <(echo "${files1[*]}" | tr ' ' '\n' | sort) <(echo "${files2[*]}" | tr ' ' '\n' | sort)))

# 초기화
total_files=0
same_files=0
different_files=0

# 다른 파일 목록을 저장할 배열 초기화
different_files_list=()

# 각 공통 파일에 대해 diff를 수행하고 결과를 출력합니다.
for file in "${common_files[@]}"; do
    result=$(diff -q "$dir1/$file" "$dir2/$file")
    total_files=$((total_files + 1))

    if [ -z "$result" ]; then
        same_files=$((same_files + 1))
    else
        different_files=$((different_files + 1))
        different_files_list+=("$file")  # 다른 파일의 목록에 추가
    fi
done

# 통계 출력
echo -e "\n[비교 결과 통계]"
echo "총 파일 수: $total_files"
echo "동일한 파일 수: $same_files"
echo "다른 파일 수: $different_files"

# 다른 파일 목록 출력
if [ "$different_files" -gt 0 ]; then
    echo -e "\n[다른 파일 목록]"
    for file in "${different_files_list[@]}"; do
        echo "$file"
    done
fi