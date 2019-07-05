#!/usr/bin/env bash
#
# TODO with release message

set -e

script_usage() {
    cat <<EOF
  -T <minutes>          Estimated job length in minutes, used to auto-set queue name
  -q <queuename>        Possible values for <queuename> are "verylong.q", "long.q"
                        and "short.q". See below for details
                        Default is "long.q".
EOF
    exit 0
}

# 显示帮助
[[ "$1" = "" || "$1" = "-h" || "$1" = "--help" ]] && script_usage

#getopt 命令的选项说明：
#-a 使getopt长选项支持"-"符号打头，必须与-l同时使用
#-l 后面接getopt支持长选项列表
#-n program如果getopt处理参数返回错误，会指出是谁处理的这个错误，这个在调用多个脚本时，很有用
#-o 后面接短参数选项，这种用法与getopts类似，
#-u 不给参数列表加引号，默认是加引号的（不使用-u选项），例如在加不引号的时候 --longopt "select * from db1.table1" $2只会取到select ，而不是完整的SQL语句。
# 示例：
# TEMP=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "test.sh" -- "$@"`
# a 后没有冒号，表示没有参数
# b 后跟一个冒号，表示有一个必要参数
# c 后跟两个冒号，表示有一个可选参数(可选参数必须紧贴选项)
# -n 出错时的信息
# -- 也是一个选项，比如 要创建一个名字为 -f 的目录，会使用 mkdir -- -f ,
#    在这里用做表示最后一个选项(用以判定 while 的结束)
# $@ 从命令行取出参数列表(不能用用 $* 代替，因为 $* 将所有的参数解释成一个字符串
#                         而 $@ 是一个参数数组)

TEMP=`getopt -o ab:c:: -l apple,banana:,cherry:: -- "$@"`

# 判定 getopt 的执行时候有错，错误信息输出到 STDERR
if [[ $? != 0 ]]
then
	echo "Terminating....."
	exit 1
fi

# 重新排列参数的顺序
# 使用eval 的目的是为了防止参数中有shell命令，被错误的扩展。
eval set -- "${TEMP}"

# 处理具体的选项
while true; do
	case "$1" in
		-a|--apple)
			echo "option a"
			shift ;;
		-b|--banana)
			echo "option b, argument $2"
			shift 2 ;;
		-c|--cherry)
			case "$2" in
				"") # 选项 c 带一个可选参数，如果没有指定就为空
					echo "option c, no argument"
					shift 2 ;;
				*)
					echo "option c, argument $2"
					shift 2 ;;
			esac ;;
		--)
		    echo "$1"
			shift; break ;;
		*)
			echo "Internal error!"
			exit 1 ;;
		esac
done

echo $@

#显示除选项外的参数(不包含选项的参数都会排到最后)
# arg 是 getopt 内置的变量 , 里面的值，就是处理过之后的 $@(命令行传入的参数)
#for arg do
#   echo '--> '"$arg" ;
#done

exit 0

binName="bash $(basename $0)"

if [[ -z "$1" ]]
then
    echo "Release all sub-repo to new tag version and push to remote repo"
    echo -e "Usage:\n  $binName VERSION"
    echo "Example:"
    echo "  $binName v1.0.0                     Tag for all sub-repos and push to remote repo"
    echo "  $binName v1.0.0 http-server         Tag for one sub-repo and push to remote repo"
    exit 0
fi

RELEASE_TAG=$1
TARGET_BRANCH=master
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

SUB_REPOS=$2

if [[ -z "$2" ]]; then
    SUB_REPOS=$(ls src/)
fi

echo "Will released version: ${RELEASE_TAG}"
echo "Will released projects:"
echo ${SUB_REPOS}

TMP_DIR="/tmp/swoft-repos"
# to base dir
cd ../ && pwd

for LIB_NAME in ${SUB_REPOS} ; do
    echo ""
    echo "====== Releasing the component:【${LIB_NAME}】"

    # REMOTE_URL=`git remote get-url ${LIB_NAME}`
    REMOTE_URL="git@github.com:swoft-cloud/swoft-${LIB_NAME}.git"

    echo "> rm -rf ${TMP_DIR} && mkdir ${TMP_DIR}";
    rm -rf ${TMP_DIR} && mkdir ${TMP_DIR};

    (
        cd ${TMP_DIR};
        echo "Begin clone ${REMOTE_URL} to ${TMP_DIR}"
        git clone ${REMOTE_URL} . --depth=200
        git checkout ${CURRENT_BRANCH};

        # like: v2.0.0
        LAST_RELEASE=$(git describe --tags $(git rev-list --tags --max-count=1))

        if [[ -z "$LAST_RELEASE" ]]; then
            echo "There has not been any releases. Releasing $1";

            # git tag $1 -s -m "Release $1"
            git tag -a $1 -m "Release $1"
            git push origin --tags
        else
            echo "Last release $LAST_RELEASE";

            CHANGES_SINCE_LAST_RELEASE=$(git log --oneline --decorate "$LAST_RELEASE"...master)

            if [[ ! -z "$CHANGES_SINCE_LAST_RELEASE" ]]; then
                echo "There are changes since last release. Releasing $1";

                # git tag $1 -s -m "Release $1"
                git tag -a $1 -m "Release $1"
                git push origin --tags
            else
                echo "No change since last release.";
            fi
        fi
    )
done

echo ""
echo "Completed!"
exit
