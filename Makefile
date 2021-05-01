V_FILES=${wildcard *.v}
OK_FILES=${wildcard *.ok}
TEST_NAMES=${sort ${subst .ok,,${OK_FILES}}}
TEST_RAWS=${addsuffix .raw,${TEST_NAMES}}
TEST_OUTS=${addsuffix .out,${TEST_NAMES}}
TEST_DIFFS=${addsuffix .diff,${TEST_NAMES}}
TEST_RESULTS=${addsuffix .result,${TEST_NAMES}}
TEST_TESTS=${addsuffix .test,${TEST_NAMES}}
TEST_VCDS=${addsuffix .vcd,${TEST_NAMES}}

all : cpu

cpu : Makefile ${V_FILES}
	iverilog -o cpu ${V_FILES}

${LIB_OC_FILES} : %.o : Makefile %.c
	gcc -MMD ${CFLAGS} -c -o $@ $*.c

${LIB_OS_FILES} : %.o : Makefile %.s
	gcc -MMD ${CFLAGS} -c -o $@ $*.s

${O_FILES} : %.o : Makefile %.c
	gcc -MMD ${CFLAGS} -c -o $@ $*.c

${TEST_RAWS} : %.raw : Makefile cpu %.hex
	@echo "failed to run" > $*.raw
	@rm -f $*.cycles
	-cp $*.hex mem.hex
	(/usr/bin/time --quiet -o $*.time -f "%E" timeout 10 ./cpu > $*.raw 2> $*.cycles); if [ $$? -eq 124 ]; then echo "timeout" > $*.time; fi
	-cp cpu.vcd $*.vcd

${TEST_OUTS} : %.out : Makefile %.raw
	@echo "no output" > $*.out
	-grep -v "VCD info: dumpfile cpu.vcd opened for output" $*.raw > $*.out

${TEST_DIFFS} : %.diff : Makefile %.out %.ok
	@echo "failed to diff" > $*.diff
	-diff -a $*.out $*.ok > $*.diff 2>&1 || true

${TEST_RESULTS} : %.result : Makefile %.diff
	@echo "fail" > $*.result
	(test \! -s $*.diff && echo "pass" > $*.result) || true

${TEST_TESTS} : %.test : Makefile %.result
	@echo "$* ... `cat $*.result` [`cat $*.time`]"

test : ${TEST_TESTS};

clean:
	-rm -rf cpu *.out *.diff *.raw *.out *.result *.time *.cycles *.vcd

######### remote things ##########

ORIGIN_URL ?= ${shell git config --get remote.origin.url}
ORIGIN_REPO = ${shell echo ${ORIGIN_URL} | sed -e 's/.*://'}
STUDENT_NAME = ${shell echo ${ORIGIN_REPO} | sed -e 's/.*_//'}
PROJECT_NAME = ${shell echo ${ORIGIN_REPO} | sed -e 's/_${STUDENT_NAME}$$//'}
GIT_SERVER = ${shell echo ${ORIGIN_URL} | sed -e 's/:.*//'}


origin:
	@echo "repo     : ${ORIGIN_REPO}"
	@echo "project  : ${PROJECT_NAME}"
	@echo "students : ${STUDENT_NAME}"
	@echo "server   : ${GIT_SERVER}"

get_tests:
	test -d all_tests || git clone ${GIT_SERVER}:${PROJECT_NAME}__tests all_tests
	(cd all_tests ; git pull)
	@echo ""
	@echo "Tests copied to all_tests (cd all_tests)"
	@echo "   Please don't add the all_tests directory to git"
	@echo ""

get_summary:
	test -d all_results || git clone ${GIT_SERVER}:${PROJECT_NAME}__results all_results
	(cd all_results ; git pull)
	python tools/summarize.py all_results

get_results:
	test -d my_results || git clone ${GIT_SERVER}:${PROJECT_NAME}_${STUDENT_NAME}_results my_results
	(cd my_results ; git pull)
	@(cd my_results;                                                      \
		for i in *.result; do                                         \
			name=$$(echo $$i | sed -e 's/\..*//');                \
			echo "$$name `cat $$name.result` `cat $$name.time`";  \
		done;                                                         \
		echo "";                                                      \
		echo "`grep pass *.result | wc -l` / `ls *.result | wc -l`";  \
	)
	@echo ""
	@echo "More details in my_results (cd my_results)"
	@echo "    Please don't add my_results directory to git"
	@echo ""

get_submission:
	test -d my_submission || git clone ${GIT_SERVER}:${PROJECT_NAME}_${STUDENT_NAME} my_submission
	(cd my_submission && git pull)
	@echo ""
	@echo "A fresh copy of your submission is in my_submissions"
	@echo "    Please don't add my_submission to git"
	@echo "    Please don't do any development in my_submission"
	@echo "    It is here to help you view what you've submitted"
	@echo ""

diff_submission: clean get_submission
	@echo "======================================================================"
	@echo "Here are the differences between what you have and what the server has"
	@echo "   More details in my_submission                                      "
	@echo "   Please remember that the server will replace some of your files    "
	@echo "   before running your code. Those changes are not shown here.        "
	@echo "======================================================================"
	@diff -rqyl . my_submission --exclude=.git --exclude=my_submission || true
	@echo ""
