#!/bin/bash
GREEN="\033[0;32m"

echo -e "${GREEN}시스템 최적화작업을 시작합니다.${NC}"

# 시스템 청소 및 불필요한 패키지 제거
echo "불필요한 패키지 및 캐시 제거 중..."
sudo apt autoremove -y && rm /root/*.deb && apt-get clean && sudo rm -rf /tmp/* && rm -rf ~/.cache/*
sudo rm -f /root/*.sh /root/*.rz

# APT 캐시 및 백업 데이터 정리
sudo apt-get autoclean
sudo rm -rf /var/cache/apt/archives/* /var/backups/*
sudo rm -f /var/cache/apt/pkgcache.bin /var/cache/apt/srcpkgcache.bin

# 오래된 로그 파일 삭제
sudo find /var/log -type f -name "*.log" -exec rm -f {} \;
sudo journalctl --vacuum-time=3d  # 3일 이전의 journal 로그 삭제

# 메모리 스왑 청소 (사용하지 않은 메모리를 해제)
sudo swapoff -a && sudo swapon -a

# 커널 업데이트 후 사용하지 않는 오래된 커널 제거
sudo apt-get remove --purge $(dpkg -l | awk '/^rc/ { print $2 }') -y

# Docker 관련 정리 작업
echo "Docker 관련 정리 작업을 실행 중..."
docker container prune -f  # 중지된 모든 컨테이너 제거
docker image prune -a -f   # 사용하지 않는 모든 이미지 제거
docker volume prune -f     # 사용하지 않는 모든 볼륨 제거
docker system prune -a -f  # 사용하지 않는 모든 데이터 정리

# Docker 로그 정리 스크립트 생성 및 크론잡 설정
echo -e '#!/bin/bash\ndocker ps -q | xargs -I {} docker logs --tail 0 {} > /dev/null' | sudo tee /usr/local/bin/docker-log-cleanup.sh
sudo chmod +x /usr/local/bin/docker-log-cleanup.sh
echo '0 0 * * * /usr/local/bin/docker-log-cleanup.sh' | sudo crontab -

# 사용되지 않는 스냅샷 제거
sudo lvremove --force $(lvs --noheadings -o lv_path | grep '_snapshot')

# 모든 파티션에서 디스크 사용량 최적화
sudo fstrim -av

# 최적화 완료 메시지 출력
echo "스토리지 최적화가 완료되었습니다!"

echo -e "${YELLOW}모든작업이 완료되었습니다.${NC}"
echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"